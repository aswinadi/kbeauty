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
    protected $query;

    public function __construct($query)
    {
        $this->query = $query;
    }

    public function collection()
    {
        return $this->query->get();
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
        return [
            $recap->date,
            $recap->employee?->full_name,
            $recap->office?->name,
            $this->formatType($recap->type),
            $recap->check_in,
            $recap->check_out,
            $recap->remark,
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1 => ['font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']], 'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => '4A5568']]],
        ];
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
            default => $type,
        };
    }
}
