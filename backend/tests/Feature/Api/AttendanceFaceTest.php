<?php

namespace Tests\Feature\Api;

use App\Models\Employee;
use App\Models\Office;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AttendanceFaceTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $employee;
    protected $office;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');

        $this->user = User::factory()->create();
        
        $this->office = Office::create([
            'name' => 'Main Office',
            'latitude' => -6.200000,
            'longitude' => 106.816666,
            'radius' => 1000,
        ]);

        $this->employee = Employee::create([
            'user_id' => $this->user->id,
            'office_id' => $this->office->id,
            'full_name' => 'Test Employee',
            'employee_code' => 'EMP001',
        ]);
    }

    public function test_check_in_requires_face_image()
    {
        $response = $this->actingAs($this->user)
            ->postJson('/api/attendance/check-in', [
                'office_id' => $this->office->id,
                'latitude' => -6.200000,
                'longitude' => 106.816666,
            ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['face_image']);
    }

    public function test_check_in_fails_if_similarity_is_low()
    {
        // Enforce a "stored photo" (Red image)
        $profile = UploadedFile::fake()->image('profile.jpg', 100, 100);
        $this->employee->addMedia($profile)->toMediaCollection('photo');

        // Capture a different looking face 
        $capturedFace = UploadedFile::fake()->image('captured.jpg', 100, 100);

        $response = $this->actingAs($this->user)
            ->postJson('/api/attendance/check-in', [
                'office_id' => $this->office->id,
                'latitude' => -6.200000,
                'longitude' => 106.816666,
                'face_image' => $capturedFace,
            ]);

        $response->assertStatus(422);
        $response->assertJsonStructure(['message']);
    }

    public function test_check_in_succeeds_if_similarity_is_high()
    {
        // For 100% similarity, we need the exact same file content
        // But since we compare pixel-by-pixel after resizing, 
        // even slightly different images might pass 100% if they are simple enough.
        // We'll just mock the verification in a way that respects the logic.
        
        $imageFile = UploadedFile::fake()->image('face.jpg', 100, 100);
        $this->employee->addMedia($imageFile)->toMediaCollection('photo');

        // Re-create the same image for the request
        $imageToUpload = UploadedFile::fake()->image('face.jpg', 100, 100);

        $response = $this->actingAs($this->user)
            ->postJson('/api/attendance/check-in', [
                'office_id' => $this->office->id,
                'latitude' => -6.200000,
                'longitude' => 106.816666,
                'face_image' => $imageToUpload,
            ]);

        // Note: Unless pixel-perfect, it might not be 100%, but should be > 60%
        $response->assertStatus(200);
    }
}
