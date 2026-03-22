<?php

namespace App\Filament\Resources\AttendanceRecaps\Pages;

use App\Filament\Resources\AttendanceRecaps\AttendanceRecapResource;
use Filament\Resources\Pages\ListRecords;
use Filament\Actions\Action;

class ListAttendanceRecaps extends ListRecords
{
    protected static string $resource = AttendanceRecapResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('download_excel')
                ->label('Excel')
                ->icon('heroicon-o-document-arrow-down')
                ->color('success')
                ->action(fn () => $this->downloadExcel()),
            Action::make('download_pdf')
                ->label('PDF')
                ->icon('heroicon-o-document-arrow-down')
                ->color('danger')
                ->action(fn () => $this->downloadPdf()),
        ];
    }

    public function downloadExcel()
    {
        $data = $this->getRecapData();
        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\AttendanceRecapExport($data), 
            'attendance-recap-' . now()->format('Y-m-d') . '.xlsx'
        );
    }

    public function downloadPdf()
    {
        $records = $this->getRecapData();
        
        $filters = $this->tableFilters;
        $period = 'Semua Waktu';
        if (!empty($filters['date_range']['from']) || !empty($filters['date_range']['to'])) {
            $from = $filters['date_range']['from'] ? \Carbon\Carbon::parse($filters['date_range']['from'])->format('d/m/Y') : '...';
            $to = $filters['date_range']['to'] ? \Carbon\Carbon::parse($filters['date_range']['to'])->format('d/m/Y') : '...';
            $period = "$from - $to";
        }

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('reports.attendance-recap', [
            'records' => $records,
            'period' => $period,
        ]);
        
        return response()->streamDownload(
            fn () => print($pdf->output()),
            'attendance-recap-' . now()->format('Y-m-d') . '.pdf'
        );
    }

    protected function getRecapData()
    {
        $filters = $this->tableFilters;
        
        // Define date range
        $fromDate = $filters['date_range']['from'] ?? now()->startOfMonth()->toDateString();
        $toDate = $filters['date_range']['to'] ?? now()->toDateString();
        
        // Get all active employees (excluding super admin if needed, but usually report shows all)
        // Match user's request for mobile to exclude super_admin if requested, but for attendance recap, we usually show everyone.
        $employees = \App\Models\Employee::whereHas('user', function ($q) {
            $q->whereDoesntHave('roles', function ($q) {
                $q->where('name', 'super_admin');
            });
        })->with('user')->get();
        
        // Fetch actual attendance records for the range
        $records = $this->getFilteredTableQuery()->get()->groupBy(['date', 'employee_id']);
        
        $data = collect();
        $current = \Carbon\Carbon::parse($fromDate);
        $end = \Carbon\Carbon::parse($toDate);
        
        // Build Cartesian Product (Date x Employee)
        while ($current <= $end) {
            $dateStr = $current->toDateString();
            foreach ($employees as $employee) {
                $recap = $records[$dateStr][$employee->id][0] ?? null;
                
                if ($recap) {
                    $data->push($recap);
                } else {
                    // Create a placeholder record for the "left join" effect
                    $data->push(new \App\Models\AttendanceRecap([
                        'date' => $dateStr,
                        'employee_id' => $employee->id,
                        'type' => 'absent',
                        'check_in' => null,
                        'check_out' => null,
                        'remark' => '-',
                    ])->setRelation('employee', $employee));
                }
            }
            $current->addDay();
        }
        
        return $data->sortBy([['date', 'desc'], ['employee.full_name', 'asc']]);
    }
}
