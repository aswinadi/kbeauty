<?php

namespace App\Traits;

use Filament\Actions\Action;

trait HasStandardPageActions
{
    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }

    protected function getBackAction(): Action
    {
        return Action::make('back')
            ->label('Back')
            ->color('gray')
            ->url($this->getResource()::getUrl('index'));
    }
}
