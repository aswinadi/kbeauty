<?php

namespace App\Filament\Resources\CustomerPortfolios\Schemas;

use App\Models\Customer;
use App\Models\PosTransaction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\SpatieMediaLibraryFileUpload;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class CustomerPortfolioForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Customer Portfolio Details')
                    ->components([
                        Select::make('customer_id')
                            ->relationship('customer', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Select::make('pos_transaction_id')
                            ->relationship('posTransaction', 'transaction_number')
                            ->searchable()
                            ->preload()
                            ->label('Transaction'),
                        SpatieMediaLibraryFileUpload::make('image')
                            ->collection('portfolio_images')
                            ->multiple()
                            ->image()
                            ->openable()
                            ->label('Photos')
                            ->columnSpanFull(),
                        Textarea::make('notes')
                            ->maxLength(65535)
                            ->columnSpanFull(),
                    ])->columns(2),
            ]);
    }
}
