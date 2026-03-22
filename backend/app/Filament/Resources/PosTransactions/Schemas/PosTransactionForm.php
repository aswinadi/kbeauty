<?php

namespace App\Filament\Resources\PosTransactions\Schemas;

use App\Models\Bundle;
use App\Models\Customer;
use App\Models\Employee;
use App\Models\Product;
use App\Models\Service;
use App\Models\Shift;
use App\Models\PaymentType;
use Filament\Forms\Get;
use Filament\Forms\Set;
use Filament\Forms\Components\Radio;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Grid;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\MorphToSelect;
use Filament\Forms\Components\Placeholder;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Illuminate\Support\Str;

class PosTransactionForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Transaction Info')
                    ->components([
                        TextInput::make('transaction_number')
                            ->disabled()
                            ->dehydrated()
                            ->default(fn () => 'POS-' . date('YmdHis') . '-' . Str::upper(Str::random(4))),
                        Select::make('customer_id')
                            ->relationship('customer', 'name')
                            ->searchable()
                            ->preload()
                            ->createOptionForm([
                                TextInput::make('name')->required(),
                                TextInput::make('phone'),
                                TextInput::make('email')->email(),
                            ]),
                        Select::make('shift_id')
                            ->relationship('shift', 'id', fn ($query) => $query->where('status', 'open'))
                            ->label('Active Shift')
                            ->required()
                            ->default(fn () => Shift::where('status', 'open')->orderBy('start_time', 'desc')->first()?->id),
                    ])->columns(3),

                Section::make('Items')
                    ->components([
                        Repeater::make('items')
                            ->relationship('items')
                            ->schema([
                                MorphToSelect::make('item')
                                    ->types([
                                        MorphToSelect\Type::make(Service::class)
                                            ->titleAttribute('name'),
                                        MorphToSelect\Type::make(Product::class)
                                            ->titleAttribute('name'),
                                        MorphToSelect\Type::make(Bundle::class)
                                            ->titleAttribute('name'),
                                    ])
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function ($state, $set, $get) {
                                        if (!$state) return;
                                        $type = $state['type'];
                                        $id = $state['id'];
                                        $model = $type::find($id);
                                        if ($model) {
                                            $set('price', $model->price);
                                            $qty = $get('quantity') ?: 1;
                                            $set('subtotal', $model->price * $qty);
                                        }
                                    }),
                                Select::make('employee_id')
                                    ->relationship('employee', 'name')
                                    ->label('Nailist/Staff')
                                    ->required()
                                    ->searchable()
                                    ->preload(),
                                TextInput::make('quantity')
                                    ->numeric()
                                    ->default(1)
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(fn ($state, $set, $get) => $set('subtotal', $state * $get('price'))),
                                TextInput::make('price')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->disabled()
                                    ->dehydrated(),
                                TextInput::make('subtotal')
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->disabled()
                                    ->dehydrated(),
                            ])
                            ->columns(5)
                            ->live()
                            ->afterStateUpdated(fn ($set, $get) => self::updateTotals($set, $get)),
                    ]),

                Section::make('Payment')
                    ->components([
                        TextInput::make('discount_amount')
                            ->numeric()
                            ->default(0)
                            ->prefix('Rp')
                            ->live()
                            ->afterStateUpdated(fn ($set, $get) => self::updateTotals($set, $get)),
                        Placeholder::make('total_amount_placeholder')
                            ->label('Total Amount')
                            ->content(fn ($get) => 'Rp ' . number_format($get('total_amount') ?: 0, 0, ',', '.')),
                        Placeholder::make('final_amount_placeholder')
                            ->label('Final Amount')
                            ->content(fn ($get) => 'Rp ' . number_format($get('final_amount') ?: 0, 0, ',', '.')),
                        TextInput::make('total_amount')->hidden()->dehydrated(),
                        TextInput::make('final_amount')->hidden()->dehydrated(),
                        
                        Repeater::make('payments')
                            ->relationship('payments')
                            ->schema([
                                Radio::make('payment_type_id')
                                    ->label('Payment Method')
                                    ->options(fn () => PaymentType::where('is_active', true)->pluck('name', 'id'))
                                    ->columns(2)
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function ($state, $set, $get) {
                                        if (!$state) return;
                                        
                                        $paymentType = PaymentType::find($state);
                                        $typeName = $paymentType?->name;
                                        
                                        // Set payment method name for backward compatibility or display
                                        $set('payment_method', $typeName);

                                        // Auto-calculate amount for non-Tunai
                                        if ($typeName !== 'Tunai') {
                                            $finalAmount = (float) $get('../../final_amount');
                                            $otherPayments = $get('../../payments') ?: [];
                                            $currentId = $get('id'); // This might be tricky in a repeater
                                            
                                            $paidAlready = 0;
                                            foreach ($otherPayments as $key => $payment) {
                                                // Simplified: sum all but this one
                                                if (isset($payment['amount'])) {
                                                    $paidAlready += (float) $payment['amount'];
                                                }
                                            }
                                            // Subtract the current payment's previous amount if it was already summed
                                            $paidAlready -= (float) ($get('amount') ?: 0);
                                            
                                            $remaining = max(0, $finalAmount - $paidAlready);
                                            $set('amount', $remaining);
                                        }
                                    }),
                                TextInput::make('amount')
                                    ->numeric()
                                    ->required()
                                    ->prefix('Rp')
                                    ->live()
                                    ->afterStateUpdated(function ($state, $set, $get) {
                                        $moneyReceived = (float) ($get('money_received') ?: 0);
                                        if ($moneyReceived > 0) {
                                            $set('change_amount', max(0, $moneyReceived - (float) $state));
                                        }
                                    }),
                                TextInput::make('bank_name')
                                    ->label('Bank Name')
                                    ->placeholder('e.g., BCA, Mandiri')
                                    ->required(fn ($get) => in_array($get('payment_method'), ['Credit Card', 'Debit Card']))
                                    ->visible(fn ($get) => in_array($get('payment_method'), ['Credit Card', 'Debit Card'])),
                                
                                Grid::make(1)
                                    ->schema([
                                        TextInput::make('money_received')
                                            ->numeric()
                                            ->prefix('Rp')
                                            ->label('Money Received')
                                            ->live()
                                            ->afterStateUpdated(function ($state, $set, $get) {
                                                $amount = (float) ($get('amount') ?: 0);
                                                $set('change_amount', max(0, (float) $state - $amount));
                                            }),
                                        Radio::make('quick_cash')
                                            ->label('Quick Cash')
                                            ->options([
                                                100000 => '100k',
                                                50000 => '50k',
                                                20000 => '20k',
                                                10000 => '10k',
                                                5000 => '5k',
                                                2000 => '2k',
                                                1000 => '1k',
                                            ])
                                            ->columns(4)
                                            ->live()
                                            ->afterStateUpdated(function ($state, $set, $get) {
                                                if (!$state) return;
                                                $current = (float) ($get('money_received') ?: 0);
                                                $newAmount = $current + (float) $state;
                                                $set('money_received', $newAmount);
                                                
                                                $amount = (float) ($get('amount') ?: 0);
                                                $set('change_amount', max(0, $newAmount - $amount));
                                                
                                                $set('quick_cash', null); // Reset to allow repeated clicks
                                            }),
                                        TextInput::make('change_amount')
                                            ->numeric()
                                            ->prefix('Rp')
                                            ->label('Change Amount')
                                            ->disabled()
                                            ->dehydrated(),
                                    ])
                                    ->visible(fn ($get) => $get('payment_method') === 'Tunai'),
                                
                                TextInput::make('payment_method')->hidden()->dehydrated(),
                            ])
                            ->columns(2)
                            ->columnSpanFull(),
                    ])->columns(3),
            ]);
    }

    public static function updateTotals($set, $get)
    {
        $items = $get('items') ?: [];
        $total = 0;
        foreach ($items as $item) {
            $total += (float) ($item['subtotal'] ?: 0);
        }
        $set('total_amount', $total);
        $discount = (float) ($get('discount_amount') ?: 0);
        $set('final_amount', max(0, $total - $discount));
    }
}
