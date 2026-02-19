<?php

namespace App\Filament\Pages;

use Filament\Pages\Page;

use \Filament\Actions\Action;
use \Filament\Forms\Components\DatePicker;
use \Filament\Forms\Components\Select;
use \Filament\Forms\Concerns\InteractsWithForms;
use \Filament\Forms\Contracts\HasForms;
use \Filament\Schemas\Components\Actions;
use \Filament\Schemas\Components\Section;
use \Filament\Schemas\Schema;
use \Illuminate\Contracts\View\View;
use \Livewire\Attributes\Url;
use \UnitEnum;

class StockCardReport extends Page implements HasForms
{
    use InteractsWithForms;

    protected static string|\UnitEnum|null $navigationGroup = 'Reports';
    protected static ?int $navigationSort = 1;
    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-document-text';

    protected string $view = 'filament.pages.stock-card-report';

    #[Url]
    public string $report_type = 'summary';

    #[Url]
    public ?int $product_id = null;

    #[Url]
    public ?string $start_date = null;

    #[Url]
    public ?string $end_date = null;

    public function mount(): void
    {
        $this->form->fill([
            'report_type' => $this->report_type,
            'product_id' => $this->product_id,
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
                        Select::make('report_type')
                            ->label('Report Type')
                            ->options([
                                'summary' => 'Summary (Global)',
                                'detail' => 'Detail (Per Location)',
                            ])
                            ->default('summary')
                            ->required()
                            ->reactive(),
                        Select::make('product_id')
                            ->label('Product')
                            ->options(\App\Models\Product::all()->pluck('name', 'id'))
                            ->required()
                            ->searchable()
                            ->preload(),
                        DatePicker::make('start_date')
                            ->label('Start Date')
                            ->required(),
                        DatePicker::make('end_date')
                            ->label('End Date')
                            ->required(),
                    ])
                    ->columns(4),
                Actions::make([
                    Action::make('filter')
                        ->label('Filter')
                        ->action(function () {
                            $data = $this->form->getState();
                            $this->report_type = $data['report_type'];
                            $this->product_id = $data['product_id'];
                            $this->start_date = $data['start_date'];
                            $this->end_date = $data['end_date'];
                        }),
                ]),
            ]);
    }

    public function getViewData(): array
    {
        if (!$this->product_id) {
            return [
                'report_type' => $this->report_type,
                'data' => [],
                'movements' => [],
                'initial_balance' => 0,
            ];
        }

        $startDate = \Carbon\Carbon::parse($this->start_date)->startOfDay();
        $endDate = \Carbon\Carbon::parse($this->end_date)->endOfDay();

        if ($this->report_type === 'detail') {
            $locations = \App\Models\Location::all();
            $data = [];

            foreach ($locations as $location) {
                // Initial Balance
                $initialIn = \App\Models\InventoryMovement::where('product_id', $this->product_id)
                    ->where('to_location_id', $location->id)
                    ->where('created_at', '<', $startDate)
                    ->sum('qty');

                $initialOut = \App\Models\InventoryMovement::where('product_id', $this->product_id)
                    ->where('from_location_id', $location->id)
                    ->where('created_at', '<', $startDate)
                    ->sum('qty');

                $initialBalance = $initialIn - $initialOut;

                // Period Movements
                $in = \App\Models\InventoryMovement::where('product_id', $this->product_id)
                    ->where('to_location_id', $location->id)
                    ->whereBetween('created_at', [$startDate, $endDate])
                    ->sum('qty');

                $out = \App\Models\InventoryMovement::where('product_id', $this->product_id)
                    ->where('from_location_id', $location->id)
                    ->whereBetween('created_at', [$startDate, $endDate])
                    ->sum('qty');

                $data[] = [
                    'location_name' => $location->name,
                    'initial_balance' => $initialBalance,
                    'in' => $in,
                    'out' => $out,
                    'final_balance' => $initialBalance + $in - $out,
                ];
            }

            return [
                'report_type' => 'detail',
                'data' => $data,
            ];

        } else {
            // Summary (Global)

            $initialIn = \App\Models\InventoryMovement::where('product_id', $this->product_id)
                ->whereNotNull('to_location_id')
                ->where('created_at', '<', $startDate)
                ->sum('qty');

            $initialOut = \App\Models\InventoryMovement::where('product_id', $this->product_id)
                ->whereNotNull('from_location_id')
                ->where('created_at', '<', $startDate)
                ->sum('qty');

            $initialBalance = $initialIn - $initialOut;

            $movements = \App\Models\InventoryMovement::where('product_id', $this->product_id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->with(['user', 'reference', 'toLocation', 'fromLocation'])
                ->orderBy('created_at', 'asc')
                ->get();

            return [
                'report_type' => 'summary',
                'movements' => $movements,
                'initial_balance' => $initialBalance,
            ];
        }
    }
}
