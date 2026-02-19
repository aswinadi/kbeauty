<x-filament-panels::page>
    {{ $this->form }}

    @php
        $data = $this->getViewData();
        $movements = $data['movements'];
        $balance = $data['initial_balance'];
    @endphp

    @if($this->product_id)
        <div class="fi-section rounded-xl bg-white shadow-sm ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
            <div class="overflow-x-auto">
                <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400">
                    <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                        <tr>
                            <th scope="col" class="px-6 py-3">Date</th>
                            <th scope="col" class="px-6 py-3">Reference</th>
                            <th scope="col" class="px-6 py-3">User</th>
                            <th scope="col" class="px-6 py-3 text-center">In</th>
                            <th scope="col" class="px-6 py-3 text-center">Out</th>
                            <th scope="col" class="px-6 py-3 text-right">Balance</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr
                            class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                            <td colspan="5" class="px-6 py-4 font-bold text-right">
                                Initial Balance
                            </td>
                            <td class="px-6 py-4 font-bold text-right">
                                {{ $balance }}
                            </td>
                        </tr>
                        @forelse ($movements as $movement)
                            @php
                                $in = 0;
                                $out = 0;

                                if ($this->location_id) {
                                    // Specific Location View
                                    if ($movement->to_location_id == $this->location_id) {
                                        $in = $movement->qty;
                                    }
                                    if ($movement->from_location_id == $this->location_id) {
                                        $out = $movement->qty;
                                    }
                                } else {
                                    // Global View (All Locations)
                                    // Only count strict In/Out. Transfers are neutral.
                                    if ($movement->to_location_id && !$movement->from_location_id) {
                                        $in = $movement->qty;
                                    }
                                    if ($movement->from_location_id && !$movement->to_location_id) {
                                        $out = $movement->qty;
                                    }
                                    // Transfers (both set) result in 0 change to global balance
                                }

                                $balance = $balance + $in - $out;
                            @endphp
                            <tr
                                class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                                <td class="px-6 py-4">
                                    {{ $movement->created_at->timezone('Asia/Jakarta')->format('d M Y H:i') }}
                                </td>
                                <td class="px-6 py-4">
                                    <div class="font-medium text-gray-900 dark:text-white">
                                        {{ $movement->type }}
                                    </div>
                                    <div class="text-xs text-gray-500">
                                        {{ class_basename($movement->reference_type) }} #{{ $movement->reference_id }}
                                    </div>
                                    @if($movement->notes)
                                        <div class="text-xs text-gray-400 italic">
                                            {{ $movement->notes }}
                                        </div>
                                    @endif
                                </td>
                                <td class="px-6 py-4">
                                    {{ $movement->user->name ?? '-' }}
                                </td>
                                <td class="px-6 py-4 text-center text-green-600 font-medium">
                                    {{ $in > 0 ? $in : '-' }}
                                </td>
                                <td class="px-6 py-4 text-center text-red-600 font-medium">
                                    {{ $out > 0 ? $out : '-' }}
                                </td>
                                <td class="px-6 py-4 text-right font-bold">
                                    {{ $balance }}
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="px-6 py-4 text-center">
                                    No movements found in this period.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    @else
        <div
            class="flex flex-col items-center justify-center p-6 text-center rounded-xl bg-white shadow-sm ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
            <div class="text-lg font-medium text-gray-900 dark:text-white">
                Select Product
            </div>
            <div class="text-sm text-gray-500 dark:text-gray-400">
                Please use the filter form above to generate the stock card.
            </div>
        </div>
    @endif
</x-filament-panels::page>