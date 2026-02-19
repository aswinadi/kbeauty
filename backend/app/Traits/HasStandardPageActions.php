<?php

namespace App\Traits;

use Filament\Actions\Action;

trait HasStandardPageActions
{
    protected function getRedirectUrl(): string
    {
        if (method_exists($this, 'getResource')) {
            return $this->getResource()::getUrl('index');
        }

        return '/admin';
    }

    protected function getBackAction(): Action
    {
        $url = '/admin';

        if (method_exists($this, 'getResource')) {
            $url = $this->getResource()::getUrl('index');
        }

        return Action::make('back')
            ->label('Back')
            ->color('gray')
            ->url($url);
    }
}
