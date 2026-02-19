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
                @if($this->report_type === 'detail')
                    {{-- DETAIL VIEW (Per Location) --}}
                    <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400">
                        <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                            <tr>
                                <th scope="col" class="px-4 py-3 min-w-[150px]">Location</th>
                                <th scope="col" class="px-4 py-3 text-right w-32">Initial</th>
                                <th scope="col" class="px-4 py-3 text-right w-24">In</th>
                                <th scope="col" class="px-4 py-3 text-right w-24">Out</th>
                                <th scope="col" class="px-4 py-3 text-right w-32">Current Stock</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($data['data'] as $row)
                                <tr
                                    class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                                    <td class="px-4 py-4 font-medium text-gray-900 dark:text-white">
                                        {{ $row['location_name'] }}
                                    </td>
                                    <td class="px-4 py-4 text-right">
                                        {{ $row['initial_balance'] }}
                                    </td>
                                    <td class="px-4 py-4 text-right text-green-600">
                                        {{ $row['in'] }}
                                    </td>
                                    <td class="px-4 py-4 text-right text-red-600">
                                        {{ $row['out'] }}
                                    </td>
                                    <td class="px-4 py-4 text-right font-bold">
                                        {{ $row['final_balance'] }}
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="px-4 py-4 text-center">
                                        No locations found.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                @else
                    {{-- SUMMARY VIEW (Global Movements) --}}
                    @php
                        $movements = $data['movements'];
                        $balance = $data['initial_balance'];
                    @endphp
                    <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400">
                        <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                            <tr>
                                <th scope="col" class="px-4 py-3 whitespace-nowrap w-32">Date</th>
                                <th scope="col" class="px-4 py-3 min-w-[150px]">Reference</th>
                                <th scope="col" class="px-4 py-3 min-w-[150px]">Location</th>
                                <th scope="col" class="px-4 py-3 whitespace-nowrap">User</th>
                                <th scope="col" class="px-4 py-3 text-right w-24">In</th>
                                <th scope="col" class="px-4 py-3 text-right w-24">Out</th>
                                <th scope="col" class="px-4 py-3 text-right w-32">Balance</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr
                                class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                                <td colspan="6" class="px-4 py-4 font-bold text-right">
                                    Initial Balance (Global)
                                </td>
                                <td class="px-4 py-4 font-bold text-right">
                                    {{ $balance }}
                                </td>
                            </tr>
                            @forelse ($movements as $movement)
                                @php
                                    $in = 0;
                                    $out = 0;
                                    $locationLabel = '-';

                                    // Global View
                                    if ($movement->to_location_id && !$movement->from_location_id) {
                                        $in = $movement->qty;
                                        $locationLabel = $movement->toLocation->name ?? '-';
                                    } elseif ($movement->from_location_id && !$movement->to_location_id) {
                                        $out = $movement->qty;
                                        $locationLabel = $movement->fromLocation->name ?? '-';
                                    } elseif ($movement->from_location_id && $movement->to_location_id) {
                                        // Transfer
                                        // $in = 0; $out = 0; // Neutral
                                        $locationLabel = ($movement->fromLocation->name ?? '?') . ' -> ' . ($movement->toLocation->name ?? '?');
                                    }

                                    $balance = $balance + $in - $out;
                                @endphp
                                <tr
                                    class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                                    <td class="px-4 py-4 whitespace-nowrap">
                                        {{ $movement->created_at->timezone('Asia/Jakarta')->format('d M Y H:i') }}
                                    </td>
                                    <td class="px-4 py-4">
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
                                    <td class="px-4 py-4 text-xs">
                                        {{ $locationLabel }}
                                    </td>
                                    <td class="px-4 py-4 whitespace-nowrap">
                                        {{ $movement->user->name ?? '-' }}
                                    </td>
                                    <td class="px-4 py-4 text-right text-green-600 font-medium whitespace-nowrap">
                                        {{ $in > 0 ? $in : '-' }}
                                    </td>
                                    <td class="px-4 py-4 text-right text-red-600 font-medium whitespace-nowrap">
                                        {{ $out > 0 ? $out : '-' }}
                                    </td>
                                    <td class="px-4 py-4 text-right font-bold whitespace-nowrap">
                                        {{ $balance }}
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="px-4 py-4 text-center">
                                        No movements found in this period.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                @endif
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