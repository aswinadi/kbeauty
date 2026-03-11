<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\AbsentAttendance;
use App\Models\Office;
use App\Models\Employee;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    public function offices()
    {
        return response()->json(Office::all());
    }

    public function getStatus(Request $request)
    {
        $employee = $request->user()->employee;
        if (!$employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $today = Carbon::today()->toDateString();
        $attendance = Attendance::where('employee_id', $employee->id)
            ->where('date', $today)
            ->first();

        return response()->json([
            'checked_in' => $attendance ? true : false,
            'checked_out' => ($attendance && $attendance->check_out) ? true : false,
            'attendance' => $attendance
        ]);
    }

    public function history(Request $request)
    {
        $employee = $request->user()->employee;
        if (!$employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $attendances = Attendance::where('employee_id', $employee->id)
            ->with('office')
            ->orderBy('date', 'desc')
            ->get();

        $absents = AbsentAttendance::where('employee_id', $employee->id)
            ->with(['office', 'media'])
            ->orderBy('date', 'desc')
            ->get();

        return response()->json([
            'attendances' => $attendances,
            'absents' => $absents
        ]);
    }

    public function checkIn(Request $request)
    {
        $request->validate([
            'office_id' => 'required|exists:offices,id',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $employee = $request->user()->employee;
        if (!$employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $office = Office::findOrFail($request->office_id);
        $distance = $this->calculateDistance(
            $request->latitude,
            $request->longitude,
            $office->latitude,
            $office->longitude
        );

        if ($distance > $office->radius) {
            return response()->json([
                'message' => 'Anda berada di luar radius kantor (' . round($distance) . 'm). Radius maksimal: ' . $office->radius . 'm',
            ], 422);
        }

        $today = Carbon::today()->toDateString();
        $now = Carbon::now()->toTimeString();

        $attendance = Attendance::updateOrCreate(
            ['employee_id' => $employee->id, 'date' => $today],
            [
                'office_id' => $office->id,
                'check_in' => $now,
                'check_in_lat' => $request->latitude,
                'check_in_long' => $request->longitude,
                'status' => $this->determineStatus($now),
            ]
        );

        return response()->json([
            'message' => 'Check-in berhasil',
            'attendance' => $attendance
        ]);
    }

    public function checkOut(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $employee = $request->user()->employee;
        if (!$employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $today = Carbon::today()->toDateString();
        $attendance = Attendance::where('employee_id', $employee->id)
            ->where('date', $today)
            ->first();

        if (!$attendance) {
            return response()->json(['message' => 'Anda belum melakukan check-in hari ini'], 422);
        }

        $office = $attendance->office;
        $distance = $this->calculateDistance(
            $request->latitude,
            $request->longitude,
            $office->latitude,
            $office->longitude
        );

        if ($distance > $office->radius) {
            return response()->json([
                'message' => 'Anda berada di luar radius kantor (' . round($distance) . 'm). Radius maksimal: ' . $office->radius . 'm',
            ], 422);
        }

        $now = Carbon::now()->toTimeString();
        $attendance->update([
            'check_out' => $now,
            'check_out_lat' => $request->latitude,
            'check_out_long' => $request->longitude,
        ]);

        return response()->json([
            'message' => 'Check-out berhasil',
            'attendance' => $attendance
        ]);
    }

    public function requestAbsent(Request $request)
    {
        $request->validate([
            'office_id' => 'required|exists:offices,id',
            'date' => 'required|date',
            'type' => 'required|in:sick,leave,late,early_out',
            'reason' => 'nullable|string',
            'images' => 'nullable|array',
            'images.*' => 'image|max:5120', // Max 5MB per image
        ]);

        $employee = $request->user()->employee;
        if (!$employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        $absent = DB::transaction(function () use ($request, $employee) {
            $absent = AbsentAttendance::create([
                'employee_id' => $employee->id,
                'office_id' => $request->office_id,
                'date' => $request->date,
                'type' => $request->type,
                'reason' => $request->reason,
                'status' => 'pending',
            ]);

            if ($request->hasFile('images')) {
                foreach ($request->file('images') as $image) {
                    $absent->addMedia($image)->toMediaCollection('attachments');
                }
            }

            return $absent;
        });

        return response()->json([
            'message' => 'Permohonan berhasil dikirim',
            'absent' => $absent->load('media')
        ]);
    }

    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $theta = $lon1 - $lon2;
        $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) +  cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
        $dist = acos($dist);
        $dist = rad2deg($dist);
        $miles = $dist * 60 * 1.1515;
        return $miles * 1609.344; // Convert to meters
    }

    private function determineStatus($checkInTime)
    {
        // Example logic: mark as late if check in after 09:00:00
        $limit = Carbon::createFromTimeString('09:00:00');
        $checkIn = Carbon::createFromTimeString($checkInTime);
        
        return $checkIn->gt($limit) ? 'late' : 'present';
    }
}
