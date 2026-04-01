<?php

namespace App\Exports;

use App\Models\AttendanceRecap;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class AttendanceRecapExport implements FromCollection, WithHeadings, WithMapping, WithStyles, ShouldAutoSize
{
    protected $data;

    public function __construct($data)
    {
        $this->data = $data;
    }

    public function collection()
    {
        return $this->data;
    }

    public function headings(): array
    {
        return [
            'Tanggal',
            'Karyawan',
            'Kantor',
            'Tipe',
            'Masuk',
            'Pulang',
            'Catatan',
        ];
    }

    public function map($recap): array
    {
        if (isset($recap->is_header) && $recap->is_header) {
            return [
                \Carbon\Carbon::parse($recap->date)->translatedFormat('l, d F Y'),
                '', '', '', '', '', ''
            ];
        }

        return [
            \Carbon\Carbon::parse($recap->date)->format('d/m/Y'),
            $recap->employee?->full_name,
            $recap->office?->name,
            $this->formatType($recap->type),
            $recap->check_in ? \Carbon\Carbon::parse($recap->check_in)->format('H:i') : '-',
            $recap->check_out ? \Carbon\Carbon::parse($recap->check_out)->format('H:i') : '-',
            $recap->remark,
        ];
    }

    public function styles(Worksheet $sheet)
    {
        $styles = [
            1 => [
                'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
                'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => '4A5568']]
            ],
        ];

        // Track header row styles
        $rowIndex = 2; // Data starts at row 2
        foreach ($this->data as $record) {
            if (isset($record->is_header) && $record->is_header) {
                $styles[$rowIndex] = [
                    'font' => ['bold' => true],
                    'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => 'EDF2F7']]
                ];
                // Merge cells for the header
                $sheet->mergeCells("A{$rowIndex}:G{$rowIndex}");
            }
            $rowIndex++;
        }

        return $styles;
    }

    protected function formatType($type)
    {
        return match ($type) {
            'present' => 'Hadir',
            'late' => 'Terlambat',
            'early_out' => 'Pulang Awal',
            'sick' => 'Sakit',
            'leave' => 'Cuti',
            'izin' => 'Izin',
            'absent' => 'Tanpa Keterangan',
            default => $type,
        };
    }
}
