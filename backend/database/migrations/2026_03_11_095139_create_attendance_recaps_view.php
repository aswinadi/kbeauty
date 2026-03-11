<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        \DB::statement("DROP VIEW IF EXISTS attendance_recaps");
        \DB::statement("
            CREATE VIEW attendance_recaps AS
            SELECT 
                CONCAT('att_', id) as id, 
                employee_id, 
                office_id, 
                date, 
                status as type, 
                check_in, 
                check_out, 
                NULL as remark,
                'attendance' as source
            FROM attendances
            UNION ALL
            SELECT 
                CONCAT('abs_', id) as id, 
                employee_id, 
                office_id, 
                date, 
                type, 
                NULL as check_in, 
                NULL as check_out, 
                reason as remark,
                'absent' as source
            FROM absent_attendances
            WHERE status = 'approved'
        ");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        \DB::statement("DROP VIEW IF EXISTS attendance_recaps");
    }
};
