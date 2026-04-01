<!DOCTYPE html>
<html>
<head>
    <title>Rekap Kehadiran</title>
    <style>
        body { font-family: 'Helvetica', 'Arial', sans-serif; color: #333; line-height: 1.5; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #444; padding-bottom: 10px; }
        .header h1 { margin: 0; text-transform: uppercase; font-size: 24px; color: #1a202c; }
        .header p { margin: 5px 0; color: #718096; }
        .meta { margin-bottom: 20px; font-size: 12px; }
        .meta table { border: none; width: auto; margin-top: 0; }
        .meta td { border: none; padding: 2px 0; padding-right: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 11px; }
        th, td { border: 1px solid #cbd5e0; padding: 10px 8px; text-align: left; }
        th { background-color: #f7fafc; color: #2d3748; font-weight: bold; text-transform: uppercase; }
        tr:nth-child(even) { background-color: #fcfcfc; }
        .status-badge { padding: 3px 6px; border-radius: 4px; font-size: 10px; font-weight: bold; color: white; display: inline-block; }
        .success { background-color: #48bb78; }
        .warning { background-color: #ed8936; }
        .danger { background-color: #f56565; }
        .info { background-color: #4299e1; }
        .gray { background-color: #a0aec0; }
        .footer { margin-top: 30px; text-align: right; font-size: 10px; color: #a0aec0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Laporan Rekap Kehadiran</h1>
        <p>K-Beauty Inventory System</p>
    </div>

    <div class="meta">
        <table>
            <tr>
                <td><strong>Periode:</strong></td>
                <td>{{ $period ?? 'Semua Waktu' }}</td>
            </tr>
            <tr>
                <td><strong>Tanggal Cetak:</strong></td>
                <td>{{ now()->translatedFormat('d F Y H:i') }}</td>
            </tr>
        </table>
    </div>

    <table>
        <thead>
            <tr>
                <th>Karyawan</th>
                <th>Kantor</th>
                <th>Tipe</th>
                <th>Masuk</th>
                <th>Pulang</th>
                <th>Catatan</th>
            </tr>
        </thead>
        <tbody>
            @php $currentDate = null; @endphp
            @foreach($records as $record)
                @if($currentDate != $record->date)
                    @php $currentDate = $record->date; @endphp
                    <tr style="background-color: #edf2f7; font-weight: bold;">
                        <td colspan="6">{{ \Carbon\Carbon::parse($currentDate)->translatedFormat('l, d F Y') }}</td>
                    </tr>
                @endif
                <tr>
                    <td><strong>{{ $record->employee?->full_name }}</strong></td>
                    <td>{{ $record->office?->name }}</td>
                    <td>
                        @php
                            $label = match ($record->type) {
                                'present' => 'Hadir',
                                'late' => 'Terlambat',
                                'early_out' => 'Pulang Awal',
                                'sick' => 'Sakit',
                                'leave' => 'Cuti',
                                'izin' => 'Izin',
                                'absent' => 'Tanpa Keterangan',
                                default => $record->type,
                            };
                            $class = match ($record->type) {
                                'present' => 'success',
                                'late' => 'warning',
                                'sick' => 'danger',
                                'leave', 'early_out', 'izin' => 'info',
                                'absent' => 'gray',
                                default => 'gray',
                            };
                        @endphp
                        <span class="status-badge {{ $class }}">{{ $label }}</span>
                    </td>
                    <td>{{ $record->check_in ? \Carbon\Carbon::parse($record->check_in)->format('H:i') : '-' }}</td>
                    <td>{{ $record->check_out ? \Carbon\Carbon::parse($record->check_out)->format('H:i') : '-' }}</td>
                    <td>{{ $record->remark ?? '-' }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        Dicetak secara otomatis oleh sistem pada {{ now()->format('d/m/Y H:i') }}
    </div>
</body>
</html>
