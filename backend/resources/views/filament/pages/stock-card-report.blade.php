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
                    <table class="w-full text-sm text-left rtl:text-right text-gray-500 dark:text-gray-400 table-fixed">
                        <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
                            <tr>
                                <th scope="col" class="px-6 py-3 w-32">Date</th>
                                <th scope="col" class="px-6 py-3 w-auto">Transaction Details</th>
                                <th scope="col" class="px-6 py-3 text-right whitespace-nowrap w-32">Qty</th>
                                <th scope="col" class="px-6 py-3 text-right whitespace-nowrap w-40">Balance</th>
                            </tr>
                        </thead>
                        <tbody>
                            {{-- Initial Balance Row --}}
                            <tr class="bg-gray-50/50 border-b dark:bg-gray-800/50 dark:border-gray-700">
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span class="text-xs font-semibold text-gray-500 uppercase">Start</span>
                                </td>
                                <td class="px-6 py-4 font-medium text-gray-900 dark:text-white">
                                    Initial Balance
                                </td>
                                <td class="px-6 py-4 text-right text-gray-400">
                                    -
                                </td>
                                <td class="px-6 py-4 font-bold text-right text-gray-900 dark:text-white">
                                    {{ number_format($balance, 0) }}
                                </td>
                            </tr>

                            @forelse ($movements as $movement)
                                @php
                                    $in = 0;
                                    $out = 0;
                                    $locationLabel = '-';
                                    $qtyDisplay = 0;
                                    $qtyClass = 'text-gray-500';

                                    // Logic to determine In/Out and Location
                                    if ($movement->to_location_id && !$movement->from_location_id) {
                                        $in = $movement->qty;
                                        $locationLabel = $movement->toLocation->name ?? '-';
                                        $qtyDisplay = "+ " . number_format($in, 0);
                                        $qtyClass = 'text-green-600 font-bold';
                                    } elseif ($movement->from_location_id && !$movement->to_location_id) {
                                        $out = $movement->qty;
                                        $locationLabel = $movement->fromLocation->name ?? '-';
                                        $qtyDisplay = "- " . number_format($out, 0);
                                        $qtyClass = 'text-red-600 font-bold';
                                    } elseif ($movement->from_location_id && $movement->to_location_id) {
                                        // Transfer
                                        $locationLabel = ($movement->fromLocation->name ?? '?') . ' → ' . ($movement->toLocation->name ?? '?');
                                        // Transfers don't change global stock, but let's show movement
                                        $qtyDisplay = "TRF";
                                        $qtyClass = 'text-blue-600 font-medium';
                                    }

                                    $balance = $balance + $in - $out;
                                @endphp
                                <tr
                                    class="border-b dark:border-gray-700 odd:bg-white even:bg-gray-50 dark:odd:bg-gray-800 dark:even:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 transition duration-150">
                                    {{-- Date Column --}}
                                    <td class="px-6 py-4 align-top">
                                        <div class="flex flex-col">
                                            <span class="font-medium text-gray-900 dark:text-white">
                                                {{ $movement->created_at->timezone('Asia/Jakarta')->format('d M Y') }}
                                            </span>
                                            <span class="text-xs text-gray-500">
                                                {{ $movement->created_at->timezone('Asia/Jakarta')->format('H:i') }}
                                            </span>
                                        </div>
                                    </td>

                                    {{-- Details Column --}}
                                    <td class="px-6 py-4 align-top">
                                        <div class="flex flex-col gap-1">
                                            <div class="font-medium text-gray-900 dark:text-white">
                                                {{ $movement->type }}
                                                <span class="text-gray-400 font-normal mx-1">/</span>
                                                <span
                                                    class="text-xs text-gray-500 uppercase tracking-wider border border-gray-200 rounded px-1.5 py-0.5">
                                                    {{ class_basename($movement->reference_type) }} #{{ $movement->reference_id }}
                                                </span>
                                            </div>

                                            <div class="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-300 mt-1">
                                                <div
                                                    class="flex items-center gap-1 bg-gray-100 dark:bg-gray-700 px-2 py-0.5 rounded text-xs">
                                                    <!-- Raw SVG Map Pin -->
                                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"
                                                        class="text-gray-500"
                                                        style="width: 16px !important; height: 16px !important; min-width: 16px; min-height: 16px;">
                                                        <path fill-rule="evenodd"
                                                            d="M9.69 18.933l.003.001C9.89 19.02 10 19 10 19s.11.02.308-.066l.002-.001.006-.003.018-.008a5.741 5.741 0 00.281-.14c.186-.096.446-.24.757-.433.62-.384 1.445-.966 2.274-1.765C15.302 14.988 17 12.493 17 9A7 7 0 103 9c0 3.492 1.698 5.988 3.355 7.584a13.731 13.731 0 002.273 1.765 11.842 11.842 0 00.976.544l.062.029.006.003.003.001zM10 13a4 4 0 100-8 4 4 0 000 8z"
                                                            clip-rule="evenodd" />
                                                    </svg>
                                                    {{ $locationLabel }}
                                                </div>
                                                <span class="text-gray-300">|</span>
                                                <div class="flex items-center gap-1 text-xs">
                                                    <!-- Raw SVG User -->
                                                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"
                                                        class="text-gray-500"
                                                        style="width: 16px !important; height: 16px !important; min-width: 16px; min-height: 16px;">
                                                        <path
                                                            d="M10 8a3 3 0 100-6 3 3 0 000 6zM3.465 14.493a1.23 1.23 0 00.41 1.412A9.957 9.957 0 0010 18c2.31 0 4.438-.784 6.131-2.1.43-.333.604-.903.408-1.41a7.002 7.002 0 00-13.074.003z" />
                                                    </svg>
                                                    {{ $movement->user->name ?? 'System' }}
                                                </div>
                                            </div>

                                            @if($movement->notes)
                                                <div class="text-xs text-gray-500 italic mt-1 pl-2 border-l-2 border-gray-200">
                                                    {{ $movement->notes }}
                                                </div>
                                            @endif
                                        </div>
                                    </td>

                                    {{-- Qty Column --}}
                                    <td class="px-6 py-4 text-right align-top whitespace-nowrap">
                                        <span class="{{ $qtyClass }}">
                                            {{ $qtyDisplay }}
                                        </span>
                                    </td>

                                    {{-- Balance Column --}}
                                    <td
                                        class="px-6 py-4 text-right align-top font-bold text-gray-900 dark:text-white whitespace-nowrap">
                                        {{ number_format($balance, 0) }}
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="4" class="px-6 py-12 text-center text-gray-500">
                                        <div class="flex flex-col items-center justify-center">
                                            <x-heroicon-o-document-text class="w-12 h-12 text-gray-300 mb-2" />
                                            <p>No movements found in this period.</p>
                                        </div>
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