<?php

namespace App\Filament\Resources\InventoryOuts\Pages;

use App\Filament\Resources\InventoryOuts\InventoryOutResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageInventoryOuts extends ManageRecords
{
    protected static string $resource = InventoryOutResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()
                ->mutateFormDataUsing(function (array $data): array {
                    $data['user_id'] = auth()->id();
                    $data['type'] = 'out';

                    return $data;
                })
                ->after(function ($record) {
                    foreach ($record->items as $item) {
                        \App\Models\InventoryMovement::create([
                            'product_id' => $item->product_id,
                            'from_location_id' => $record->location_id,
                            'qty' => $item->qty,
                            'type' => 'manual_out',
                            'user_id' => $record->user_id,
                        ]);
                    }
                }),
        ];
    }
}
