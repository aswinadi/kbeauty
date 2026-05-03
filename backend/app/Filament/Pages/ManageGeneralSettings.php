<?php

namespace App\Filament\Pages;

use App\Models\GeneralSetting;
use App\Models\Location;
use Filament\Schemas\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Schemas\Components\Actions;
use Filament\Schemas\Components\EmbeddedSchema;
use Filament\Schemas\Components\Form as SchemaForm;
use Filament\Schemas\Schema;
use Filament\Support\Enums\Alignment;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Actions\Action;

class ManageGeneralSettings extends Page implements HasForms
{
    use InteractsWithForms;
    protected static string | \BackedEnum | null $navigationIcon = 'heroicon-o-cog-6-tooth';

    public static function getNavigationGroup(): ?string
    {
        return 'POS';
    }

    protected static ?string $navigationLabel = 'General Settings';

    protected static ?string $title = 'General Settings';

    protected static ?int $navigationSort = 100;

    public ?array $data = [];

    public function mount(): void
    {
        $settings = GeneralSetting::firstOrNew();
        $this->form->fill($settings->toArray());
    }

    public function form(Schema $form): Schema
    {
        return $form
            ->schema([
                Section::make('Store Information')
                    ->schema([
                        TextInput::make('store_name')
                            ->label('Store Name')
                            ->required(),
                        TextInput::make('store_address')
                            ->label('Store Address')
                            ->placeholder('e.g., Jl. Jendral Sudirman No. 123'),
                        TextInput::make('store_phone')
                            ->label('Store Phone')
                            ->placeholder('e.g., 08123456789'),
                        TextInput::make('bill_footer')
                            ->label('Bill Footer Message')
                            ->placeholder('e.g., Thank you for visiting us!')
                            ->helperText('This message will appear at the bottom of printed and WhatsApp receipts.'),
                    ])->columns(2),

                Section::make('POS & Attendance Settings')
                    ->schema([
                        \Filament\Forms\Components\Select::make('pos_item_layout')
                            ->label('POS Item Layout')
                            ->options([
                                'grid' => 'Grid View',
                                'list' => 'List View',
                            ])
                            ->default('grid')
                            ->required(),
                        \Filament\Forms\Components\TextInput::make('face_similarity_threshold')
                            ->label(__('messages.fields.face_similarity_threshold'))
                            ->numeric()
                            ->default(80)
                            ->step(1)
                            ->minValue(0)
                            ->maxValue(100)
                            ->required()
                            ->suffix('%')
                            ->helperText('Minimum similarity percentage required for face verification during check-in/out.'),
                        \Filament\Forms\Components\Select::make('pos_display_location_id')
                            ->label('POS Display Location')
                            ->helperText('Default location to deduct stock for POS transactions.')
                            ->options(Location::pluck('name', 'id'))
                            ->searchable()
                            ->preload(),
                    ])->columns(2),

                Section::make('App Versioning')
                    ->description('Manage mobile app updates and mandatory versioning.')
                    ->schema([
                        \Filament\Forms\Components\Placeholder::make('current_app_version')
                            ->label('Current Repository Version')
                            ->content($this->getAppVersion())
                            ->extraAttributes(['class' => 'text-primary-600 font-bold']),
                        \Filament\Forms\Components\TextInput::make('latest_version')
                            ->label('Latest App Version')
                            ->placeholder('e.g., 1.2.0')
                            ->helperText('The version number that triggers an update prompt.'),
                        \Filament\Forms\Components\TextInput::make('apk_url')
                            ->label('APK Download URL')
                            ->url()
                            ->placeholder('e.g., https://example.com/app-latest.apk')
                            ->helperText('Direct link to download the latest APK file.'),
                        \Filament\Forms\Components\Toggle::make('is_mandatory_update')
                            ->label('Is Mandatory Update')
                            ->default(false)
                            ->helperText('If enabled, users will be forced to update to use the app.'),
                    ])->columns(2),
            ])
            ->statePath('data');
    }

    public function content(Schema $schema): Schema
    {
        return $schema
            ->components([
                SchemaForm::make([EmbeddedSchema::make('form')])
                    ->livewireSubmitHandler('save')
                    ->footer([
                        Actions::make($this->getFormActions())
                            ->alignment(Alignment::Start),
                    ]),
            ]);
    }

    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label(__('filament-panels::resources/pages/edit-record.form.actions.save.label'))
                ->submit('save'),
        ];
    }

    public function save(): void
    {
        $data = $this->form->getState();
        $settings = GeneralSetting::first() ?? new GeneralSetting();
        $settings->fill($data);
        $settings->save();

        Notification::make()
            ->success()
            ->title('Settings saved successfully.')
            ->send();
    }

    protected function getAppVersion(): string
    {
        try {
            $pubspecPath = base_path('../mobile/pubspec.yaml');
            if (file_exists($pubspecPath)) {
                $content = file_get_contents($pubspecPath);
                if (preg_match('/version:\s*([^\s]+)/', $content, $matches)) {
                    return $matches[1];
                }
            }
        } catch (\Exception $e) {
            // Silently fail
        }
        return 'v1.1.0+2'; // Fallback to last known if file not found in production
    }
}
