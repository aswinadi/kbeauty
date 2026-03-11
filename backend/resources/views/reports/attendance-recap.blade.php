<!DOCTYPE html>
<html>
<head>
    <title>Rekap Kehadiran</title>
    <style>
        body { font-family: sans-serif; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .success { color: green; }
        .warning { color: orange; }
        .danger { color: red; }
        .info { color: blue; }
        .gray { color: gray; }
    </style>
</head>
<body>
    <h2 style="text-align: center;">Rekap Kehadiran</h2>
    <table>
        <thead>
            <tr>
                <th>Tanggal</th>
                <th>Karyawan</th>
                <th>Kantor</th>
                <th>Tipe</th>
                <th>Masuk</th>
                <th>Pulang</th>
                <th>Catatan</th>
            </tr>
        </thead>
        <tbody>
            @foreach($records as $record)
                <tr>
                    <td>{{ $record->date }}</td>
                    <td>{{ $record->employee?->name }}</td>
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
                                default => $record->type,
                            };
                            $class = match ($record->type) {
                                'present' => 'success',
                                'late' => 'warning',
                                'sick' => 'danger',
                                'leave', 'early_out' => 'info',
                                default => 'gray',
                            };
                        @endphp
                        <span class="{{ $class }}">{{ $label }}</span>
                    </td>
                    <td>{{ $record->check_in ?? '-' }}</td>
                    <td>{{ $record->check_out ?? '-' }}</td>
                    <td>{{ $record->remark ?? '-' }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
