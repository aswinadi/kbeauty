<?php

namespace App\Filament\Pages;

use App\Models\GeneralSetting;
use Filament\Schemas\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Schemas\Schema;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Actions\Action;

class ManageGeneralSettings extends Page implements HasForms
{
    use InteractsWithForms;
    protected static string | \BackedEnum | null $navigationIcon = 'heroicon-o-cog-6-tooth';

    protected static ?string $navigationLabel = 'General Settings';

    protected static ?string $title = 'General Settings';

    protected static ?int $navigationSort = 100;

    protected string $view = 'filament.pages.manage-general-settings';

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
