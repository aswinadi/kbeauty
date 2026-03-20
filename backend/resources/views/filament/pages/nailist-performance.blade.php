<x-filament-panels::page>
    <div class="space-y-6">
        {{ $this->form }}
        
        <div class="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-gray-200 dark:border-gray-800">
            {{ $this->table }}
        </div>
    </div>
</x-filament-panels::page>
