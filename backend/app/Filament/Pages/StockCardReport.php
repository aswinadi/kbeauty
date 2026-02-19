<?php

namespace App\Filament\Pages;

use Filament\Pages\Page;
use Filament\Tables\Table;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Columns\TextColumn;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Schemas\Components\Actions;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Contracts\View\View;
use Livewire\Attributes\Url;
use App\Models\Location;
use App\Models\InventoryMovement;
use App\Models\Product;
use Carbon\Carbon;
use Filament\Actions\Action as HeaderAction;

class StockCardReport extends Page implements HasForms, HasTable
{
    use InteractsWithForms;
    use InteractsWithTable;
    use \App\Traits\HasStandardPageActions;

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
                        Select::make('product_id')
                            ->label('Product')
                            ->options(Product::all()->pluck('name', 'id'))
                            ->required()
                            ->searchable()
                            ->preload()
                            ->reactive(),
                        Select::make('location_id')
                            ->label('Location')
                            ->options(Location::all()->pluck('name', 'id')->prepend('All Locations', ''))
                            ->default('')
                            ->reactive(),
                        DatePicker::make('start_date')
                            ->label('Start Date')
                            ->required()
                            ->reactive(),
                        DatePicker::make('end_date')
                            ->label('End Date')
                            ->required()
                            ->reactive(),
                    ])
                    ->columns(4),
                Actions::make([
                    \Filament\Actions\Action::make('filter')
                        ->label('Generate Report')
                        ->action(function () {
                            $data = $this->form->getState();
                            $this->location_id = $data['location_id'] ?: null;
                            $this->product_id = $data['product_id'];
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
                $query = Location::query();
                if ($this->location_id) {
                    $query->where('id', $this->location_id);
                }
                return $query;
            })
            ->columns([
                TextColumn::make('name')
                    ->label('Location')
                    ->weight('bold'),
                TextColumn::make('initial')
                    ->label('Initial')
                    ->alignRight()
                    ->state(fn(Location $record) => $this->calculateStock($record, 'initial'))
                    ->summarize(\Filament\Tables\Columns\Summarizers\Sum::make()->label('Total')),
                TextColumn::make('in')
                    ->label('In')
                    ->alignRight()
                    ->color('success')
                    ->state(fn(Location $record) => $this->calculateStock($record, 'in'))
                    ->summarize(\Filament\Tables\Columns\Summarizers\Sum::make()->label('')),
                TextColumn::make('out')
                    ->label('Out')
                    ->alignRight()
                    ->color('danger')
                    ->state(fn(Location $record) => $this->calculateStock($record, 'out'))
                    ->summarize(\Filament\Tables\Columns\Summarizers\Sum::make()->label('')),
                TextColumn::make('stock')
                    ->label('Stock')
                    ->alignRight()
                    ->weight('bold')
                    ->state(fn(Location $record) => $this->calculateStock($record, 'stock'))
                    ->summarize(\Filament\Tables\Columns\Summarizers\Sum::make()->label('')),
            ])
            ->emptyStateHeading('No stock data to display')
            ->emptyStateDescription($this->product_id ? 'Try adjusting your filters.' : 'Please select a product first.')
            ->paginated(false);
    }

    protected function calculateStock(Location $location, string $type): float
    {
        if (!$this->product_id)
            return 0;

        $startDate = Carbon::parse($this->start_date)->startOfDay();
        $endDate = Carbon::parse($this->end_date)->endOfDay();

        if ($type === 'initial') {
            $in = InventoryMovement::where('product_id', $this->product_id)
                ->where('to_location_id', $location->id)
                ->where('created_at', '<', $startDate)
                ->sum('qty');
            $out = InventoryMovement::where('product_id', $this->product_id)
                ->where('from_location_id', $location->id)
                ->where('created_at', '<', $startDate)
                ->sum('qty');
            return (float) ($in - $out);
        }

        if ($type === 'in') {
            return (float) InventoryMovement::where('product_id', $this->product_id)
                ->where('to_location_id', $location->id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->sum('qty');
        }

        if ($type === 'out') {
            return (float) InventoryMovement::where('product_id', $this->product_id)
                ->where('from_location_id', $location->id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->sum('qty');
        }

        if ($type === 'stock') {
            $initial = $this->calculateStock($location, 'initial');
            $in = $this->calculateStock($location, 'in');
            $out = $this->calculateStock($location, 'out');
            return $initial + $in - $out;
        }

        return 0;
    }

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
        ];
    }
}
