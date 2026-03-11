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
            'face_image' => 'required|image|max:5120',
        ]);

        $employee = $request->user()->employee;
        if (!$employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        // Face Verification
        $similarity = $this->verifyFaceSimilarity($employee, $request->file('face_image'));
        if ($similarity < 80) {
            return response()->json([
                'message' => 'Wajah tidak cocok (Kemiripan: ' . round($similarity, 2) . '%). Pastikan wajah terlihat jelas dan sesuai dengan foto profil.',
            ], 422);
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
            'message' => 'Check-in berhasil (Kemiripan: ' . round($similarity, 2) . '%)',
            'attendance' => $attendance
        ]);
    }

    public function checkOut(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'face_image' => 'required|image|max:5120',
        ]);

        $employee = $request->user()->employee;
        if (!$employee) {
            return response()->json(['message' => 'Employee record not found'], 404);
        }

        // Face Verification
        $similarity = $this->verifyFaceSimilarity($employee, $request->file('face_image'));
        if ($similarity < 80) {
            return response()->json([
                'message' => 'Wajah tidak cocok (Kemiripan: ' . round($similarity, 2) . '%). Pastikan wajah terlihat jelas dan sesuai dengan foto profil.',
            ], 422);
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
            'message' => 'Check-out berhasil (Kemiripan: ' . round($similarity, 2) . '%)',
            'attendance' => $attendance
        ]);
    }

    private function verifyFaceSimilarity($employee, $uploadedFile)
    {
        $storedPhotoPath = $employee->getFirstMediaPath('photo');
        \Log::info("Face Verification path: " . ($storedPhotoPath ?: 'NULL'));

        if (!$storedPhotoPath || !file_exists($storedPhotoPath)) {
            \Log::warning("Face Verification skipped: No stored photo found for employee " . $employee->id);
            // If no photo to compare, we return 0 to enforce enrollment/photo upload
            return 0; 
        }

        try {
            $img1 = $this->createImageFromFile($storedPhotoPath);
            $img2 = $this->createImageFromFile($uploadedFile->getPathname());

            if (!$img1 || !$img2) {
                \Log::error("Face Verification failed: Could not create images from files");
                return 0;
            }

            $size = 64;
            $thumb1 = imagecreatetruecolor($size, $size);
            $thumb2 = imagecreatetruecolor($size, $size);
            $w1 = imagesx($img1); $h1 = imagesy($img1);
            $w2 = imagesx($img2); $h2 = imagesy($img2);
            imagecopyresampled($thumb1, $img1, 0, 0, 0, 0, $size, $size, $w1, $h1);
            imagecopyresampled($thumb2, $img2, 0, 0, 0, 0, $size, $size, $w2, $h2);

            // Calculate average brightness for normalization
            $sumBright1 = 0; $sumBright2 = 0;
            for ($x = 0; $x < $size; $x++) {
                for ($y = 0; $y < $size; $y++) {
                    $c1 = imagecolorat($thumb1, $x, $y); $c2 = imagecolorat($thumb2, $x, $y);
                    $sumBright1 += (($c1 >> 16) & 0xFF) + (($c1 >> 8) & 0xFF) + ($c1 & 0xFF);
                    $sumBright2 += (($c2 >> 16) & 0xFF) + (($c2 >> 8) & 0xFF) + ($c2 & 0xFF);
                }
            }
            $avgB1 = $sumBright1 / ($size * $size * 3);
            $avgB2 = $sumBright2 / ($size * $size * 3);
            $brightnessRatio = $avgB1 > 0 ? $avgB2 / $avgB1 : 1;

            $diff = 0;
            $totalWeight = 0;
            $center = $size / 2;

            for ($x = 0; $x < $size; $x++) {
                for ($y = 0; $y < $size; $y++) {
                    $color1 = imagecolorat($thumb1, $x, $y);
                    $color2 = imagecolorat($thumb2, $x, $y);

                    $r1 = ($color1 >> 16) & 0xFF; $g1 = ($color1 >> 8) & 0xFF; $b1 = $color1 & 0xFF;
                    $r2 = ($color2 >> 16) & 0xFF; $g2 = ($color2 >> 8) & 0xFF; $b2 = $color2 & 0xFF;

                    // Normalize brightness of image 1 to match image 2 approx.
                    $r1n = min(255, $r1 * $brightnessRatio);
                    $g1n = min(255, $g1 * $brightnessRatio);
                    $b1n = min(255, $b1 * $brightnessRatio);

                    // Center weighting: weight is higher in the middle (where face is)
                    $dist = sqrt(pow($x - $center, 2) + pow($y - $center, 2));
                    $weight = max(0.1, 1 - ($dist / ($size / 1.2))); // Drop off weight towards edges

                    $diff += (abs($r1n - $r2) + abs($g1n - $g2) + abs($b1n - $b2)) * $weight;
                    $totalWeight += $weight;
                }
            }

            imagedestroy($img1); imagedestroy($img2);
            imagedestroy($thumb1); imagedestroy($thumb2);

            // Max weighted diff
            $maxWeightedDiff = $totalWeight * 3 * 255;
            $similarity = (1 - ($diff / $maxWeightedDiff)) * 100;

            \Log::info("Face Verification (Center-Weighted) similarity for employee {$employee->id}: " . round($similarity, 2) . "%");

            return $similarity;
        } catch (\Exception $e) {
            \Log::error("Face Verification exception: " . $e->getMessage());
            return 0;
        }
    }

    private function createImageFromFile($path)
    {
        $info = getimagesize($path);
        switch ($info[2]) {
            case IMAGETYPE_JPEG: return imagecreatefromjpeg($path);
            case IMAGETYPE_PNG:  return imagecreatefrompng($path);
            case IMAGETYPE_GIF:  return imagecreatefromgif($path);
            default: return null;
        }
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
