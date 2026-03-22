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

    protected static ?string $navigationGroup = 'POS';

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
                Section::make('Attendance Settings')
                    ->schema([
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
                    ])
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
}
