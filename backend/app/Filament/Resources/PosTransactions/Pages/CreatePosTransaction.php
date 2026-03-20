<?php

namespace App\Filament\Resources\PosTransactions\Pages;

use App\Filament\Resources\PosTransactions\PosTransactionResource;
use App\Models\GeneralSetting;
use App\Models\InventoryMovement;
use App\Models\Product;
use App\Models\Service;
use App\Models\Bundle;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Support\Facades\DB;

class CreatePosTransaction extends CreateRecord
{
    protected static string $resource = PosTransactionResource::class;

    protected function afterCreate(): void
    {
        $transaction = $this->record;
        
        DB::transaction(function () use ($transaction) {
            $settings = GeneralSetting::first();
            $locationId = $settings?->pos_display_location_id;

            foreach ($transaction->items as $item) {
                $this->processItemStock($item, $locationId);
            }
        });
    }

    protected function processItemStock($item, $locationId): void
    {
        if (!$locationId) return;

        $type = $item->item_type;
        $model = $item->item;

        if ($type === Product::class) {
            $this->deductStock($model->id, $item->quantity, $locationId, $item->pos_transaction_id);
        } elseif ($type === Service::class && $model->deduct_stock) {
            foreach ($model->materials as $material) {
                $this->deductStock($material->product_id, $material->quantity * $item->quantity, $locationId, $item->pos_transaction_id);
            }
        } elseif ($type === Bundle::class) {
            foreach ($model->items as $bundleItem) {
                if ($bundleItem->item_type === Product::class) {
                    $this->deductStock($bundleItem->item_id, $bundleItem->quantity * $item->quantity, $locationId, $item->pos_transaction_id);
                } elseif ($bundleItem->item_type === Service::class && $bundleItem->item->deduct_stock) {
                    foreach ($bundleItem->item->materials as $material) {
                        $this->deductStock($material->product_id, $material->quantity * $bundleItem->quantity * $item->quantity, $locationId, $item->pos_transaction_id);
                    }
                }
            }
        }
    }

    protected function deductStock($productId, $qty, $locationId, $transactionId): void
    {
        InventoryMovement::create([
            'product_id' => $productId,
            'from_location_id' => $locationId,
            'qty' => $qty,
            'type' => 'out',
            'user_id' => auth()->id(),
            'reference_id' => $transactionId,
            'reference_type' => \App\Models\PosTransaction::class,
        ]);
    }
}
