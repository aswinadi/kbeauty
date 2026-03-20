<?php

declare(strict_types=1);

namespace App\Policies;

use Illuminate\Foundation\Auth\User as AuthUser;
use App\Models\PosTransaction;
use Illuminate\Auth\Access\HandlesAuthorization;

class PosTransactionPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:PosTransaction');
    }

    public function view(AuthUser $authUser, PosTransaction $posTransaction): bool
    {
        return $authUser->can('View:PosTransaction');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:PosTransaction');
    }

    public function update(AuthUser $authUser, PosTransaction $posTransaction): bool
    {
        return $authUser->can('Update:PosTransaction');
    }

    public function delete(AuthUser $authUser, PosTransaction $posTransaction): bool
    {
        return $authUser->can('Delete:PosTransaction');
    }

    public function restore(AuthUser $authUser, PosTransaction $posTransaction): bool
    {
        return $authUser->can('Restore:PosTransaction');
    }

    public function forceDelete(AuthUser $authUser, PosTransaction $posTransaction): bool
    {
        return $authUser->can('ForceDelete:PosTransaction');
    }

    public function forceDeleteAny(AuthUser $authUser): bool
    {
        return $authUser->can('ForceDeleteAny:PosTransaction');
    }

    public function restoreAny(AuthUser $authUser): bool
    {
        return $authUser->can('RestoreAny:PosTransaction');
    }

    public function replicate(AuthUser $authUser, PosTransaction $posTransaction): bool
    {
        return $authUser->can('Replicate:PosTransaction');
    }

    public function reorder(AuthUser $authUser): bool
    {
        return $authUser->can('Reorder:PosTransaction');
    }

}