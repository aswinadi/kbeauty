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
                            ->placeholder('All Locations')
                            ->options(\App\Models\Location::all()->pluck('name', 'id'))
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
                        ->action(function () {
                            $data = $this->form->getState();
                            $this->location_id = $data['location_id'] ?? null;
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
                'movements' => [],
                'initial_balance' => 0,
            ];
        }

        $startDate = \Carbon\Carbon::parse($this->start_date)->startOfDay();
        $endDate = \Carbon\Carbon::parse($this->end_date)->endOfDay();

        // Calculate Initial Balance
        $initialInQuery = \App\Models\InventoryMovement::where('product_id', $this->product_id)
            ->where('created_at', '<', $startDate);

        $initialOutQuery = \App\Models\InventoryMovement::where('product_id', $this->product_id)
            ->where('created_at', '<', $startDate);

        if ($this->location_id) {
            $initialInQuery->where('to_location_id', $this->location_id);
            $initialOutQuery->where('from_location_id', $this->location_id);
        } else {
            // Global Balance: In is any valid 'to' (that isn't a transfer? No, all 'to' adds to physical stock at that location)
            // But for Global Stock: Transfer A->B. A loses, B gains. Net 0.
            // Formula: Sum(to) - Sum(from) works perfectly for Global too.
            $initialInQuery->whereNotNull('to_location_id');
            $initialOutQuery->whereNotNull('from_location_id');
        }

        $initialBalance = $initialInQuery->sum('qty') - $initialOutQuery->sum('qty');

        // Fetch Movements
        $movementsQuery = \App\Models\InventoryMovement::where('product_id', $this->product_id)
            ->whereBetween('created_at', [$startDate, $endDate]);

        if ($this->location_id) {
            $movementsQuery->where(function ($query) {
                $query->where('from_location_id', $this->location_id)
                    ->orWhere('to_location_id', $this->location_id);
            });
        }
        // If location_id is null (All), we fetch EVERYTHING for this product.

        $movements = $movementsQuery
            ->with(['user', 'reference'])
            ->orderBy('created_at', 'asc')
            ->get();

        return [
            'movements' => $movements,
            'initial_balance' => $initialBalance,
        ];
    }
}
