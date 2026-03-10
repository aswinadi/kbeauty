<!DOCTYPE html>
<html>

<head>
    <title>{{ $title }}</title>
    <style>
        body {
            font-family: sans-serif;
            font-size: 12px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        th,
        td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }

        th {
            background-color: #f2f2f2;
        }

        .text-right {
            text-align: right;
        }

        .footer {
            margin-top: 20px;
            font-weight: bold;
        }

        .header {
            margin-bottom: 30px;
        }

        .header h1 {
            margin-bottom: 5px;
        }

        .header p {
            margin: 2px 0;
            color: #666;
        }
    </style>
</head>

<body>
    <div class="header">
        <h1>{{ $title }}</h1>
        <p>Product: {{ $product_name }}</p>
        <p>Period: {{ $start_date }} - {{ $end_date }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>SKU</th>
                <th>Product</th>
                <th>UOM</th>
                <th>Location</th>
                <th class="text-right">Initial</th>
                <th class="text-right">In</th>
                <th class="text-right">Out</th>
                <th class="text-right">Stock</th>
                <th class="text-right">Breakdown</th>
            </tr>
        </thead>
        <tbody>
            @foreach($data as $row)
                <tr>
                    <td>{{ $row['sku'] }}</td>
                    <td>{{ $row['product'] }}</td>
                    <td>{{ $row['uom'] }}</td>
                    <td>{{ $row['location'] }}</td>
                    <td class="text-right">{{ number_format($row['initial'], 0) }}</td>
                    <td class="text-right">{{ number_format($row['in'], 0) }}</td>
                    <td class="text-right">{{ number_format($row['out'], 0) }}</td>
                    <td class="text-right">{{ number_format($row['stock'], 0) }}</td>
                    <td class="text-right">{{ $row['breakdown'] }}</td>
                </tr>
            @endforeach
        </tbody>
        <tfoot>
            <tr style="font-weight: bold; background-color: #f9f9f9;">
                <td colspan="4">TOTAL</td>
                <td class="text-right">{{ number_format(collect($data)->sum('initial'), 0) }}</td>
                <td class="text-right">{{ number_format(collect($data)->sum('in'), 0) }}</td>
                <td class="text-right">{{ number_format(collect($data)->sum('out'), 0) }}</td>
                <td class="text-right">{{ number_format(collect($data)->sum('stock'), 0) }}</td>
                <td></td>
            </tr>
        </tfoot>
    </table>
</body>

</html>