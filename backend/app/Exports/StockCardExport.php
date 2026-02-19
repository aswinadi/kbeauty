<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;

class StockCardExport implements FromArray, WithHeadings, ShouldAutoSize, WithTitle
{
    protected array $data;
    protected string $title;

    public function __construct(array $data, string $title = 'Stock Card Report')
    {
        $this->data = $data;
        $this->title = $title;
    }

    public function array(): array
    {
        return $this->data;
    }

    public function headings(): array
    {
        return [
            'Location',
            'Initial',
            'In',
            'Out',
            'Stock',
        ];
    }

    public function title(): string
    {
        return $this->title;
    }
}
