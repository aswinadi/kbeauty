<?php

namespace App\Filament\Resources\Users\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Select;
use Filament\Schemas\Schema;
use Illuminate\Support\Facades\Hash;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label(__('messages.models.user'))
                    ->required()
                    ->maxLength(255),
                TextInput::make('username')
                    ->label(__('messages.fields.username'))
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),
                TextInput::make('email')
                    ->label(__('messages.fields.email'))
                    ->email()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),
                TextInput::make('password')
                    ->label(__('messages.fields.password'))
                    ->password()
                    ->dehydrateStateUsing(fn($state) => Hash::make($state))
                    ->dehydrated(fn($state) => filled($state))
                    ->required(fn(string $context): bool => $context === 'create'),
                Select::make('roles')
                    ->label(__('messages.fields.roles'))
                    ->multiple()
                    ->relationship('roles', 'name')
                    ->preload(),
                \Filament\Forms\Components\Toggle::make('is_active')
                    ->label(__('messages.fields.status_active'))
                    ->default(true),
            ]);
    }
}
