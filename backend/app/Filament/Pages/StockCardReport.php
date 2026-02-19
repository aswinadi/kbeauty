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
    public ?int $location_id = null;

    #[Url]
    public ?int $product_id = null;

    #[Url]
    public ?string $start_date = null;

    #[Url]
    public ?string $end_date = null;

    public function mount(): void
    {
        $this->form->fill([
            'location_id' => $this->location_id,
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
                        Select::make('location_id')
                            ->label('Location')
                            ->options(\App\Models\Location::all()->pluck('name', 'id'))
                            ->required()
                            ->searchable(),
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
                        ->action(function (array $data) {
                            $this->location_id = $data['location_id'];
                            $this->product_id = $data['product_id'];
                            $this->start_date = $data['start_date'];
                            $this->end_date = $data['end_date'];
                        }),
                ]),
            ]);
    }

    public function getViewData(): array
    {
        if (!$this->location_id || !$this->product_id) {
            return [
                'movements' => [],
                'initial_balance' => 0,
            ];
        }

        $startDate = \Carbon\Carbon::parse($this->start_date)->startOfDay();
        $endDate = \Carbon\Carbon::parse($this->end_date)->endOfDay();

        // Calculate Initial Balance (movements before start date)
        $initialBalance = \App\Models\InventoryMovement::where('product_id', $this->product_id)
            ->where('to_location_id', $this->location_id) // Incoming to this location
            ->where('created_at', '<', $startDate)
            ->sum('qty');

        $outgoing = \App\Models\InventoryMovement::where('product_id', $this->product_id)
            ->where('from_location_id', $this->location_id) // Outgoing from this location
            ->where('created_at', '<', $startDate)
            ->sum('qty');

        $initialBalance -= $outgoing;

        // Fetch Movements within range
        $movements = \App\Models\InventoryMovement::where('product_id', $this->product_id)
            ->where(function ($query) {
                $query->where('from_location_id', $this->location_id)
                    ->orWhere('to_location_id', $this->location_id);
            })
            ->whereBetween('created_at', [$startDate, $endDate])
            ->with(['user', 'reference'])
            ->orderBy('created_at', 'asc')
            ->get();

        return [
            'movements' => $movements,
            'initial_balance' => $initialBalance,
        ];
    }
}
