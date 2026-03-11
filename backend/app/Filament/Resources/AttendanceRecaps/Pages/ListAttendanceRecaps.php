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
        $query = $this->getFilteredTableQuery();
        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\AttendanceRecapExport($query), 
            'attendance-recap-' . now()->format('Y-m-d') . '.xlsx'
        );
    }

    public function downloadPdf()
    {
        $records = $this->getFilteredTableQuery()->get();
        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('reports.attendance-recap', ['records' => $records]);
        return response()->streamDownload(
            fn () => print($pdf->output()),
            'attendance-recap-' . now()->format('Y-m-d') . '.pdf'
        );
    }
}
