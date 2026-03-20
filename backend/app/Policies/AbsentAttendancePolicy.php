<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\AbsentAttendance;
use Illuminate\Auth\Access\HandlesAuthorization;

class AbsentAttendancePolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:AbsentAttendance');
    }

    public function view(AuthUser $authUser, AbsentAttendance $absentAttendance): bool
    {
        return $authUser->can('View:AbsentAttendance');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:AbsentAttendance');
    }

    public function update(AuthUser $authUser, AbsentAttendance $absentAttendance): bool
    {
        return $authUser->can('Update:AbsentAttendance');
    }

    public function delete(AuthUser $authUser, AbsentAttendance $absentAttendance): bool
    {
        return $authUser->can('Delete:AbsentAttendance');
    }

    public function restore(AuthUser $authUser, AbsentAttendance $absentAttendance): bool
    {
        return $authUser->can('Restore:AbsentAttendance');
    }

    public function forceDelete(AuthUser $authUser, AbsentAttendance $absentAttendance): bool
    {
        return $authUser->can('ForceDelete:AbsentAttendance');
    }

    public function forceDeleteAny(AuthUser $authUser): bool
    {
        return $authUser->can('ForceDeleteAny:AbsentAttendance');
    }

    public function restoreAny(AuthUser $authUser): bool
    {
        return $authUser->can('RestoreAny:AbsentAttendance');
    }

    public function replicate(AuthUser $authUser, AbsentAttendance $absentAttendance): bool
    {
        return $authUser->can('Replicate:AbsentAttendance');
    }

    public function reorder(AuthUser $authUser): bool
    {
        return $authUser->can('Reorder:AbsentAttendance');
    }

}