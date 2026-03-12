<?php

namespace App\Filament\Pages;

use App\Models\GeneralSetting;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Actions\Action;

class ManageGeneralSettings extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static string $view = 'filament.pages.manage-general-settings';

    protected static ?string $navigationLabel = 'General Settings';

    protected static ?string $title = 'General Settings';

    protected static ?int $navigationSort = 100;

    public ?array $data = [];

    public function mount(): void
    {
        $settings = GeneralSetting::firstOrNew();
        $this->form->fill($settings->toArray());
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Section::make('Attendance Settings')
                    ->schema([
                        TextInput::make('face_similarity_threshold')
                            ->label('Face Similarity Threshold (%)')
                            ->numeric()
                            ->required()
                            ->minValue(0)
                            ->maxValue(100)
                            ->suffix('%')
                            ->helperText('Minimum similarity percentage required for face verification during check-in/out.'),
                    ])
            ])
            ->statePath('data');
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
