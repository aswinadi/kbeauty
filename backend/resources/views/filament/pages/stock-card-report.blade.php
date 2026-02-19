<x-filament-panels::page>
    {{ $this->form }}

    @php
        $data = $this->getViewData();
    @endphp

    @if($this->product_id)
        <div class="fi-section rounded-xl bg-white shadow-sm ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
            <div class="overflow-x-auto">
                @if(($this->report_type ?? 'summary') === 'detail')
                    {{-- DETAIL VIEW (Per Location) --}}
                    <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400 table-fixed">
                        <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                            <tr>
                                <th scope="col" class="px-6 py-3">Location</th>
                                <th scope="col" class="px-6 py-3 text-right whitespace-nowrap w-32">Initial</th>
                                <th scope="col" class="px-6 py-3 text-right whitespace-nowrap w-24">In</th>
                                <th scope="col" class="px-6 py-3 text-right whitespace-nowrap w-24">Out</th>
                                <th scope="col" class="px-6 py-3 text-right whitespace-nowrap w-32">Stock</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($data['data'] ?? [] as $row)
                                <tr
                                    class="bg-white border-b dark:bg-gray-800 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600">
                                    <td class="px-6 py-4 font-medium text-gray-900 dark:text-white truncate"
                                        title="{{ $row['location_name'] }}">
                                        {{ $row['location_name'] }}
                                    </td>
                                    <td class="px-6 py-4 text-right font-medium">
                                        {{ $row['initial_balance'] }}
                                    </td>
                                    <td class="px-6 py-4 text-right text-green-600 font-medium">
                                        {{ $row['in'] }}
                                    </td>
                                    <td class="px-6 py-4 text-right text-red-600 font-medium">
                                        {{ $row['out'] }}
                                    </td>
                                    <td class="px-6 py-4 text-right font-bold">
                                        {{ $row['final_balance'] }}
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="px-6 py-4 text-center">
                                        No locations found.
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                @else
                    {{-- SUMMARY VIEW (Global Movements) --}}
                    @php
                        $movements = $data['movements'] ?? [];
                        $balance = $data['initial_balance'] ?? 0;
                    @endphp
                    <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400">
                        <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                            <tr>
                                <th scope="col" class="px-4 py-3 whitespace-nowrap w-40">Date</th>
                                <th scope="col" class="px-4 py-3 min-w-[250px]">Reference</th>
                                <th scope="col" class="px-4 py-3 min-w-[200px]">Location</th>
                                <th scope="col" class="px-4 py-3 whitespace-nowrap min-w-[150px]">User</th>
                                <th scope="col" class="px-4 py-3 text-right whitespace-nowrap w-24">In</th>
                                <th scope="col" class="px-4 py-3 text-right whitespace-nowrap w-24">Out</th>
                                <th scope="col" class="px-4 py-3 text-right whitespace-nowrap w-32">Balance</th>
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
                                    <td class="px-4 py-4 whitespace-nowrap align-top">
                                        {{ $movement->created_at->timezone('Asia/Jakarta')->format('d M Y H:i') }}
                                    </td>
                                    <td class="px-4 py-4 align-top">
                                        <div class="font-medium text-gray-900 dark:text-white break-words">
                                            {{ $movement->type }}
                                        </div>
                                        <div class="text-xs text-gray-500 break-words">
                                            {{ class_basename($movement->reference_type) }} #{{ $movement->reference_id }}
                                        </div>
                                        @if($movement->notes)
                                            <div class="text-xs text-gray-400 italic mt-1 break-words">
                                                {{ $movement->notes }}
                                            </div>
                                        @endif
                                    </td>
                                    <td class="px-4 py-4 text-xs align-top break-words">
                                        {{ $locationLabel }}
                                    </td>
                                    <td class="px-4 py-4 whitespace-nowrap align-top">
                                        {{ $movement->user->name ?? '-' }}
                                    </td>
                                    <td class="px-4 py-4 text-right text-green-600 font-medium whitespace-nowrap align-top">
                                        {{ $in > 0 ? $in : '-' }}
                                    </td>
                                    <td class="px-4 py-4 text-right text-red-600 font-medium whitespace-nowrap align-top">
                                        {{ $out > 0 ? $out : '-' }}
                                    </td>
                                    <td class="px-4 py-4 text-right font-bold whitespace-nowrap align-top">
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