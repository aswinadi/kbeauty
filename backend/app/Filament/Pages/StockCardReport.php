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
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Exports\StockCardExport;

class StockCardReport extends Page implements HasForms, HasTable
{
    use InteractsWithForms;
    use InteractsWithTable;

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
                            ->options(Product::all()->pluck('name', 'id')->prepend('All Products', ''))
                            ->default('')
                            ->searchable()
                            ->preload(),
                        Select::make('location_id')
                            ->label('Location')
                            ->options(Location::all()->pluck('name', 'id')->prepend('All Locations', ''))
                            ->default(''),
                        DatePicker::make('start_date')
                            ->label('Start Date')
                            ->required(),
                        DatePicker::make('end_date')
                            ->label('End Date')
                            ->required(),
                    ])
                    ->columns(4),
                Actions::make([
                    \Filament\Actions\Action::make('filter')
                        ->label('Generate Report')
                        ->action(function () {
                            $data = $this->form->getState();
                            $this->location_id = $data['location_id'] ?: null;
                            $this->product_id = $data['product_id'] ?: null;
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
                $rawPairs = \Illuminate\Support\Facades\DB::table('inventory_movements')
                    ->select('product_id', 'to_location_id as location_id')
                    ->whereNotNull('to_location_id')
                    ->union(
                        \Illuminate\Support\Facades\DB::table('inventory_movements')
                            ->select('product_id', 'from_location_id as location_id')
                            ->whereNotNull('from_location_id')
                    );

                $dataWithMetadata = \Illuminate\Support\Facades\DB::table(\Illuminate\Support\Facades\DB::raw("({$rawPairs->toSql()}) as pairs"))
                    ->mergeBindings($rawPairs)
                    ->join('products', 'pairs.product_id', '=', 'products.id')
                    ->join('locations', 'pairs.location_id', '=', 'locations.id')
                    ->select([
                        \Illuminate\Support\Facades\DB::raw("CONCAT(pairs.product_id, '-', pairs.location_id) as id"),
                        'pairs.product_id',
                        'pairs.location_id',
                        'products.name as product_name',
                        'locations.name as location_name',
                    ]);

                $model = new \App\Models\InventoryMovement();
                $model->setTable('final_report');
                $model->setKeyName('id');

                return $model->newQuery()
                    ->fromSub($dataWithMetadata, 'final_report')
                    ->when($this->product_id, fn($q) => $q->where('product_id', $this->product_id))
                    ->when($this->location_id, fn($q) => $q->where('location_id', $this->location_id));
            })
            ->columns([
                TextColumn::make('product_name')
                    ->label('Product')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('location_name')
                    ->label('Location')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('quantity')
                    ->label('Quantity')
                    ->alignRight()
                    ->weight('bold')
                    ->state(fn(object $record) => $this->calculateStock($record, 'stock'))
                    ->summarize(\Filament\Tables\Columns\Summarizers\Summarizer::make()
                        ->label('')
                        ->using(fn($query) => $query->get()->sum(fn($record) => $this->calculateStock($record, 'stock')))),
            ])
            ->groups([
                'product_name',
                'location_name',
            ])
            ->defaultGroup('product_name')
            ->emptyStateHeading('No stock data to display')
            ->emptyStateDescription($this->product_id ? 'Try adjusting your filters.' : 'Please select a product first.')
            ->paginated(false);
    }

    protected function calculateStock(object $location, string $type): float
    {
        $startDate = Carbon::parse($this->start_date)->startOfDay();
        $endDate = Carbon::parse($this->end_date)->endOfDay();

        if ($type === 'initial') {
            $queryIn = InventoryMovement::where('product_id', $location->product_id)
                ->where('to_location_id', $location->location_id)
                ->where('created_at', '<', $startDate);
            $queryOut = InventoryMovement::where('product_id', $location->product_id)
                ->where('from_location_id', $location->location_id)
                ->where('created_at', '<', $startDate);

            return (float) ($queryIn->sum('qty') - $queryOut->sum('qty'));
        }

        if ($type === 'in') {
            return (float) InventoryMovement::where('product_id', $location->product_id)
                ->where('to_location_id', $location->location_id)
                ->whereBetween('created_at', [$startDate, $endDate])
                ->sum('qty');
        }

        if ($type === 'out') {
            return (float) InventoryMovement::where('product_id', $location->product_id)
                ->where('from_location_id', $location->location_id)
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

    public function exportExcel()
    {
        $data = $this->getReportData();
        $title = 'Stock Card - ' . ($this->product_id ? Product::find($this->product_id)->name : 'All Products');

        return Excel::download(new StockCardExport($data, $title), $title . '.xlsx');
    }

    public function exportPdf()
    {
        $data = $this->getReportData();
        $product_name = $this->product_id ? Product::find($this->product_id)->name : 'All Products';

        $pdf = Pdf::loadView('exports.stock-card-pdf', [
            'title' => 'Stock Card Report',
            'product_name' => $product_name,
            'start_date' => $this->start_date,
            'end_date' => $this->end_date,
            'data' => $data,
        ]);

        return response()->streamDownload(fn() => print ($pdf->output()), 'stock-card-report.pdf');
    }

    protected function getReportData(): array
    {
        $rawPairs = \Illuminate\Support\Facades\DB::table('inventory_movements')
            ->select('product_id', 'to_location_id as location_id')
            ->whereNotNull('to_location_id')
            ->union(
                \Illuminate\Support\Facades\DB::table('inventory_movements')
                    ->select('product_id', 'from_location_id as location_id')
                    ->whereNotNull('from_location_id')
            );

        $dataWithMetadata = \Illuminate\Support\Facades\DB::table(\Illuminate\Support\Facades\DB::raw("({$rawPairs->toSql()}) as pairs"))
            ->mergeBindings($rawPairs)
            ->join('products', 'pairs.product_id', '=', 'products.id')
            ->join('locations', 'pairs.location_id', '=', 'locations.id')
            ->select([
                \Illuminate\Support\Facades\DB::raw("CONCAT(pairs.product_id, '-', pairs.location_id) as id"),
                'pairs.product_id',
                'pairs.location_id',
                'products.name as product_name',
                'locations.name as location_name',
            ]);

        $model = new \App\Models\InventoryMovement();
        $model->setTable('final_report');
        $model->setKeyName('id');

        $query = $model->newQuery()
            ->fromSub($dataWithMetadata, 'final_report');

        if ($this->product_id) {
            $query->where('product_id', $this->product_id);
        }

        if ($this->location_id) {
            $query->where('location_id', $this->location_id);
        }

        return $query->reorder()->orderBy('product_name')->get()->map(fn($record) => [
            'name' => "{$record->location_name} - {$record->product_name}",
            'quantity' => $this->calculateStock($record, 'stock'),
        ])->toArray();
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
}
