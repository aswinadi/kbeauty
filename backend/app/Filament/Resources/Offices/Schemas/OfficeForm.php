<?php

namespace App\Filament\Resources\Offices\Schemas;

use Dotswan\MapPicker\Fields\Map;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class OfficeForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label(__('messages.fields.name'))
                    ->required()
                    ->maxLength(255),
                Textarea::make('address')
                    ->label(__('messages.fields.address'))
                    ->maxLength(65535)
                    ->columnSpanFull(),
                Map::make('location')
                    ->label('Lokasi')
                    ->columnSpanFull()
                    ->afterStateUpdated(function ($set, $state) {
                        $set('latitude', $state['lat']);
                        $set('longitude', $state['lng']);
                    })
                    ->afterStateHydrated(function ($set, $get, $state) {
                        $set('location', [
                            'lat' => (float) $get('latitude'),
                            'lng' => (float) $get('longitude'),
                        ]);
                    })
                    ->live()
                    ->extraControl([
                        'zoomControl' => true,
                        'mapTypeControl' => true,
                        'scaleControl' => true,
                        'streetViewControl' => true,
                        'rotateControl' => true,
                        'fullscreenControl' => true,
                        'searchBoxControl' => true,
                    ]),
                TextInput::make('latitude')
                    ->label(__('messages.attendance.latitude'))
                    ->numeric()
                    ->required()
                    ->live()
                    ->afterStateUpdated(function ($set, $get, $state) {
                        $set('location', [
                            'lat' => (float) $state,
                            'lng' => (float) $get('longitude'),
                        ]);
                    }),
                TextInput::make('longitude')
                    ->label(__('messages.attendance.longitude'))
                    ->numeric()
                    ->required()
                    ->live()
                    ->afterStateUpdated(function ($set, $get, $state) {
                        $set('location', [
                            'lat' => (float) $get('latitude'),
                            'lng' => (float) $state,
                        ]);
                    }),
                TextInput::make('radius')
                    ->label(__('messages.attendance.radius'))
                    ->numeric()
                    ->default(20)
                    ->required(),
            ]);
    }
}
