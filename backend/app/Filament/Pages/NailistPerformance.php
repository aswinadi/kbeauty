<?php

namespace App\Filament\Pages;

use App\Models\Employee;
use App\Models\PosTransactionItem;
use Filament\Pages\Page;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Schemas\Schema;
use Filament\Forms\Components\DatePicker;
use Filament\Schemas\Components\Section;
use Illuminate\Support\Facades\DB;
use BackedEnum;
use UnitEnum;

class NailistPerformance extends Page implements HasForms, HasTable
{
    use InteractsWithForms;
    use InteractsWithTable;

    protected static string|UnitEnum|null $navigationGroup = 'POS';
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-chart-bar';
    protected static ?string $title = 'Nailist Performance';
    protected string $view = 'filament.pages.nailist-performance';

    public $fromDate;
    public $toDate;

    public function mount()
    {
        $this->fromDate = now()->startOfMonth()->format('Y-m-d');
        $this->toDate = now()->endOfMonth()->format('Y-m-d');
        $this->form->fill([
            'from_date' => $this->fromDate,
            'to_date' => $this->toDate,
        ]);
    }

    public function form(Schema $form): Schema
    {
        return $form
            ->components([
                Section::make('Filter Period')
                    ->components([
                        DatePicker::make('from_date')
                            ->live()
                            ->afterStateUpdated(fn ($state) => $this->fromDate = $state),
                        DatePicker::make('to_date')
                            ->live()
                            ->afterStateUpdated(fn ($state) => $this->toDate = $state),
                    ])->columns(2)
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Employee::query()
                    ->select('employees.*')
                    ->withSum(['posTransactionItems as total_commissions' => function ($query) {
                        $query->whereHas('posTransaction', function ($q) {
                            $q->whereBetween('created_at', [$this->fromDate . ' 00:00:00', $this->toDate . ' 23:59:59']);
                        });
                        // Note: Raw calculation for commission might be needed if it's dynamic
                        // But since we stored subtotal, we can calculate based on service type.
                    }], 'subtotal') // This is a placeholder, real calculation below
            )
            ->columns([
                TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('total_services')
                    ->label('Total Services')
                    ->counts(['posTransactionItems' => function ($query) {
                        $query->whereHas('posTransaction', function ($q) {
                            $q->whereBetween('created_at', [$this->fromDate . ' 00:00:00', $this->toDate . ' 23:59:59']);
                        });
                    }]),
                TextColumn::make('commissions_calculated')
                    ->label('Total Commissions')
                    ->money('idr')
                    ->state(function (Employee $record) {
                        $items = PosTransactionItem::where('employee_id', $record->id)
                            ->whereHas('posTransaction', function ($q) {
                                $q->whereBetween('created_at', [$this->fromDate . ' 00:00:00', $this->toDate . ' 23:59:59']);
                            })
                            ->with('item')
                            ->get();
                        
                        return $items->sum(function ($item) {
                            return $item->commission; // Using the attribute defined in model
                        });
                    }),
            ]);
    }
}
