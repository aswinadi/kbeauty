<?php

namespace App\Filament\Resources\InventoryIns\Pages;

use App\Filament\Resources\InventoryIns\InventoryInResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageInventoryIns extends ManageRecords
{
    protected static string $resource = InventoryInResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->mutateFormDataUsing(function (array $data): array {
                    $data['user_id'] = auth()->id();
                    $data['type'] = 'in';

                    return $data;
                })
                ->after(function ($record) {
                    foreach ($record->items as $item) {
                        \App\Models\InventoryMovement::create([
                            'product_id' => $item->product_id,
                            'to_location_id' => $record->location_id,
                            'qty' => $item->qty,
                            'type' => 'manual_in',
                            'user_id' => $record->user_id,
                        ]);
                    }
                }),
        ];
    }
}
