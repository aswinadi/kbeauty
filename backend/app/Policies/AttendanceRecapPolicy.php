<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\AttendanceRecap;
use Illuminate\Auth\Access\HandlesAuthorization;

class AttendanceRecapPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:AttendanceRecap');
    }

    public function view(AuthUser $authUser, AttendanceRecap $attendanceRecap): bool
    {
        return $authUser->can('View:AttendanceRecap');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:AttendanceRecap');
    }

    public function update(AuthUser $authUser, AttendanceRecap $attendanceRecap): bool
    {
        return $authUser->can('Update:AttendanceRecap');
    }

    public function delete(AuthUser $authUser, AttendanceRecap $attendanceRecap): bool
    {
        return $authUser->can('Delete:AttendanceRecap');
    }

    public function restore(AuthUser $authUser, AttendanceRecap $attendanceRecap): bool
    {
        return $authUser->can('Restore:AttendanceRecap');
    }

    public function forceDelete(AuthUser $authUser, AttendanceRecap $attendanceRecap): bool
    {
        return $authUser->can('ForceDelete:AttendanceRecap');
    }

    public function forceDeleteAny(AuthUser $authUser): bool
    {
        return $authUser->can('ForceDeleteAny:AttendanceRecap');
    }

    public function restoreAny(AuthUser $authUser): bool
    {
        return $authUser->can('RestoreAny:AttendanceRecap');
    }

    public function replicate(AuthUser $authUser, AttendanceRecap $attendanceRecap): bool
    {
        return $authUser->can('Replicate:AttendanceRecap');
    }

    public function reorder(AuthUser $authUser): bool
    {
        return $authUser->can('Reorder:AttendanceRecap');
    }

}