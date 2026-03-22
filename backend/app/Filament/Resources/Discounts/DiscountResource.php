<?php

namespace App\Filament\Resources\Discounts;

use App\Filament\Resources\Discounts\Pages\ManageDiscounts;
use App\Models\Discount;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use BackedEnum;

class DiscountResource extends Resource
{
    protected static ?string $model = Discount::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-ticket';

    public static function getNavigationGroup(): ?string
    {
        return 'POS';
    }

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Discount Details')
                    ->components([
                        TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        Select::make('type')
                            ->options([
                                'fixed' => 'Fixed Amount',
                                'percentage' => 'Percentage',
                            ])
                            ->required(),
                        TextInput::make('value')
                            ->numeric()
                            ->required(),
                        Toggle::make('is_active')
                            ->required()
                            ->default(true),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('type')
                    ->formatStateUsing(fn (string $state): string => ucfirst($state)),
                TextColumn::make('value')
                    ->formatStateUsing(fn ($state, $record) => $record->type === 'percentage' ? $state . '%' : 'Rp ' . number_format($state, 0, ',', '.')),
                IconColumn::make('is_active')
                    ->boolean()
                    ->sortable(),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ManageDiscounts::route('/'),
        ];
    }
}
