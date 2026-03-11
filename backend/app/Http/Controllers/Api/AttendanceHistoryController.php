<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\AbsentAttendance;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AttendanceHistoryController extends Controller
{
    /**
     * Get attendance history for the authenticated user.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user->employee) {
            return response()->json([]);
        }

        $employeeId = $user->employee->id;

        // Fetch regular attendances
        $attendances = Attendance::where('employee_id', $employeeId)
            ->orderBy('date', 'desc')
            ->get()
            ->map(function ($a) {
                return [
                    'id' => $a->id,
                    'type' => 'attendance',
                    'date' => $a->date,
                    'status' => $a->status,
                    'check_in' => $a->check_in,
                    'check_out' => $a->check_out,
                    'formatted_date' => Carbon::parse($a->date)->format('d F Y'),
                ];
            });

        // Fetch absent records
        $absents = AbsentAttendance::where('employee_id', $employeeId)
            ->orderBy('date', 'desc')
            ->get()
            ->map(function ($a) {
                return [
                    'id' => $a->id,
                    'type' => 'absent',
                    'date' => $a->date,
                    'status' => $a->type, // e.g., sick, leave, etc.
                    'check_in' => null,
                    'check_out' => null,
                    'formatted_date' => Carbon::parse($a->date)->format('d F Y'),
                ];
            });

        // Merge and sort
        $history = $attendances->concat($absents)
            ->sortByDesc('date')
            ->values();

        return response()->json($history);
    }
}
