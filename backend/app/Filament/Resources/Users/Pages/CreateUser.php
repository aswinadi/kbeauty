<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use App\Traits\HasStandardPageActions;
use Filament\Resources\Pages\CreateRecord;

class CreateUser extends CreateRecord
{
    use HasStandardPageActions;

    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [
            $this->getBackAction(),
        ];
    }
}
