<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$rawPairs = DB::table('inventory_movements')
    ->select('product_id', 'to_location_id as location_id')
    ->whereNotNull('to_location_id')
    ->union(
        DB::table('inventory_movements')
            ->select('product_id', 'from_location_id as location_id')
            ->whereNotNull('from_location_id')
    );

$sql = $rawPairs->toSql();
echo "Raw Union SQL: $sql\n";
echo "Raw Union Count: " . $rawPairs->get()->count() . "\n";

$dataWithMetadata = DB::table(DB::raw("($sql) as pairs"))
    ->mergeBindings($rawPairs)
    ->join('products', 'pairs.product_id', '=', 'products.id')
    ->join('locations', 'pairs.location_id', '=', 'locations.id')
    ->leftJoin('units', 'products.unit_id', '=', 'units.id')
    ->select([
        DB::raw("CONCAT(pairs.product_id, '-', pairs.location_id) as id"),
        'pairs.product_id',
        'pairs.location_id',
        'products.name as product_name',
        'locations.name as location_name',
    ]);

$result = $dataWithMetadata->get();
echo "Data with Metadata Count: " . $result->count() . "\n";
foreach ($result as $row) {
    echo "ID: {$row->id}, Product: {$row->product_name}, Location: {$row->location_name}\n";
}
