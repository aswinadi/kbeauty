<?php

namespace App\Exports;

use App\Models\AttendanceRecap;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class AttendanceRecapExport implements FromCollection, WithHeadings, WithMapping
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
            $recap->employee?->name,
            $recap->office?->name,
            $this->formatType($recap->type),
            $recap->check_in,
            $recap->check_out,
            $recap->remark,
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
