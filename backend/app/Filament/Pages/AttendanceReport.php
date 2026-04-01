<?php

namespace App\Filament\Pages;

use App\Exports\AttendanceRecapExport;
use App\Models\AttendanceRecap;
use App\Models\Employee;
use App\Models\Holiday;
use App\Models\Office;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Filament\Actions\Action as HeaderAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Pages\Page;
use Filament\Schemas\Components\Actions;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Livewire\Attributes\Url;
use Maatwebsite\Excel\Facades\Excel;

class AttendanceReport extends Page implements HasForms, HasTable
{
    use InteractsWithForms;
    use InteractsWithTable;

    public static function getNavigationGroup(): ?string
    {
        return __('messages.navigation_groups.reports');
    }

    public static function getNavigationLabel(): string
    {
        return 'Rekap Kehadiran';
    }

    public function getTitle(): string
    {
        return 'Rekap Kehadiran';
    }

    protected static ?int $navigationSort = 1;
    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-document-chart-bar';

    protected string $view = 'filament.pages.attendance-report';

    #[Url]
    public ?int $employee_id = null;

    #[Url]
    public ?string $start_date = null;

    #[Url]
    public ?string $end_date = null;

    public function mount(): void
    {
        $this->form->fill([
            'employee_id' => $this->employee_id,
            'start_date' => $this->start_date ?? now()->startOfMonth()->toDateString(),
            'end_date' => $this->end_date ?? now()->endOfMonth()->toDateString(),
        ]);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make()
                    ->components([
                        Select::make('employee_id')
                            ->label(__('messages.models.employee'))
                            ->options(Employee::all()->pluck('full_name', 'id'))
                            ->searchable()
                            ->preload(),
                        DatePicker::make('start_date')
                            ->label('Start Date')
                            ->required(),
                        DatePicker::make('end_date')
                            ->label('End Date')
                            ->required(),
                    ])
                    ->columns(3),
                Actions::make([
                    \Filament\Actions\Action::make('filter')
                        ->label('Generate Report')
                        ->color('primary')
                        ->action(function () {
                            $data = $this->form->getState();
                            $this->employee_id = $data['employee_id'] ?: null;
                            $this->start_date = $data['start_date'];
                            $this->end_date = $data['end_date'];
                        }),
                ]),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(function () {
                $query = AttendanceRecap::query();
                
                // Only show if filtered
                if (!$this->start_date && !$this->end_date) {
                    return $query->whereRaw('1=0');
                }

                return $query
                    ->when($this->employee_id, fn($q) => $q->where('employee_id', $this->employee_id))
                    ->when($this->start_date, fn($q) => $q->whereDate('date', '>=', $this->start_date))
                    ->when($this->end_date, fn($q) => $q->whereDate('date', '<=', $this->end_date));
            })
            ->columns([
                TextColumn::make('date')
                    ->label(__('messages.attendance.date'))
                    ->date()
                    ->sortable(),
                TextColumn::make('employee.full_name')
                    ->label(__('messages.models.employee'))
                    ->searchable()
                    ->sortable(),
                TextColumn::make('office.name')
                    ->label(__('messages.models.office'))
                    ->sortable(),
                TextColumn::make('type')
                    ->label(__('messages.attendance.type'))
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'present' => 'success',
                        'late' => 'warning',
                        'early_out' => 'info',
                        'sick' => 'danger',
                        'leave' => 'info',
                        'izin', 'sakit', 'cuti' => 'info',
                        default => 'gray',
                    })
                    ->icon(fn (string $state): string => match ($state) {
                        'present' => 'heroicon-m-check-circle',
                        'late' => 'heroicon-m-clock',
                        'early_out' => 'heroicon-m-arrow-left-on-rectangle',
                        'sick' => 'heroicon-m-heart',
                        'leave' => 'heroicon-m-calendar-days',
                        'izin' => 'heroicon-m-document-text',
                        default => 'heroicon-m-question-mark-circle',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'present' => 'Hadir',
                        'late', 'datang terlambat' => 'Terlambat',
                        'early_out', 'pulang awal' => 'Pulang Awal',
                        'sick', 'sakit' => 'Sakit',
                        'leave', 'cuti' => 'Cuti',
                        'izin' => 'Izin',
                        default => $state,
                    }),
                TextColumn::make('check_in')
                    ->label(__('messages.attendance.check_in'))
                    ->time('H:i')
                    ->placeholder('-'),
                TextColumn::make('check_out')
                    ->label(__('messages.attendance.check_out'))
                    ->time('H:i')
                    ->placeholder('-'),
                TextColumn::make('remark')
                    ->label(__('messages.fields.notes'))
                    ->wrap()
                    ->placeholder('-'),
            ])
            ->defaultSort('date', 'desc')
            ->defaultGroup('date')
            ->groups([
                'date',
                'employee.full_name',
                'office.name',
            ])
            ->emptyStateHeading('No attendance data to display')
            ->emptyStateDescription($this->employee_id || $this->start_date ? 'Try adjusting your filters.' : 'Please select a period first.')
            ->paginated(false);
    }

    protected function getHeaderActions(): array
    {
        return [
            HeaderAction::make('exportExcel')
                ->label('Export Excel')
                ->icon('heroicon-o-arrow-down-tray')
                ->color('success')
                ->action('exportExcel'),
            HeaderAction::make('exportPdf')
                ->label('Export PDF')
                ->icon('heroicon-o-document-arrow-down')
                ->color('danger')
                ->action('exportPdf'),
        ];
    }

    public function exportExcel()
    {
        $data = $this->getRecapData();
        
        // Grouping logic for Excel: Insert header rows
        $groupedData = collect();
        $currentDate = null;
        
        foreach ($data as $record) {
            if ($currentDate !== $record->date) {
                $currentDate = $record->date;
                // Add a "Header Row" object (or a special record)
                $groupedData->push((object)[
                    'is_header' => true,
                    'date' => $currentDate,
                ]);
            }
            $groupedData->push($record);
        }

        return Excel::download(
            new AttendanceRecapExport($groupedData), 
            'attendance-recap-' . now()->format('Y-m-d') . '.xlsx'
        );
    }

    public function exportPdf()
    {
        $records = $this->getRecapData();
        
        $period = 'Semua Waktu';
        if ($this->start_date || $this->end_date) {
            $from = $this->start_date ? Carbon::parse($this->start_date)->format('d/m/Y') : '...';
            $to = $this->end_date ? Carbon::parse($this->end_date)->format('d/m/Y') : '...';
            $period = "$from - $to";
        }

        $pdf = Pdf::loadView('reports.attendance-recap', [
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
        // Define date range
        $fromDate = $this->start_date ?? now()->startOfMonth()->toDateString();
        $toDate = $this->end_date ?? now()->toDateString();

        // Get all holidays within the range
        $holidays = Holiday::where('end_date', '>=', $fromDate)
            ->where('start_date', '<=', $toDate)
            ->get();
        
        // Get all active employees (excluding super admin)
        $employees = Employee::whereHas('user', function ($q) {
            $q->whereDoesntHave('roles', function ($q) {
                $q->where('name', 'super_admin');
            });
        })->with(['user', 'office'])->get();
        
        // Fetch actual attendance records for the range
        $records = AttendanceRecap::query()
            ->when($this->employee_id, fn($q) => $q->where('employee_id', $this->employee_id))
            ->whereDate('date', '>=', $fromDate)
            ->whereDate('date', '<=', $toDate)
            ->with(['employee', 'office'])
            ->get()
            ->groupBy(['date', 'employee_id']);
        
        $data = collect();
        $current = Carbon::parse($fromDate);
        $end = Carbon::parse($toDate);
        
        // Build Cartesian Product (Date x Employee)
        while ($current <= $end) {
            $dateStr = $current->toDateString();

            // Skip holidays
            $isHoliday = $holidays->contains(function ($holiday) use ($current) {
                return $current->greaterThanOrEqualTo($holiday->start_date) && 
                       $current->lessThanOrEqualTo($holiday->end_date);
            });

            if ($isHoliday) {
                $current->addDay();
                continue;
            }
            
            // If employee_id is specifically filtered, only show that employee
            $targetEmployees = $this->employee_id 
                ? Employee::where('id', $this->employee_id)->with(['user', 'office'])->get()
                : $employees;

            foreach ($targetEmployees as $employee) {
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
                    ])->setRelation('employee', $employee)
                      ->setRelation('office', $employee->office));
                }
            }
            $current->addDay();
        }
        
        return $data->sortBy([['date', 'asc'], ['employee.full_name', 'asc']]);
    }
}
