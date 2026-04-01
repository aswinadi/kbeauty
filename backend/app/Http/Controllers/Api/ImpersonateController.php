<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ImpersonateController extends Controller
{
    /**
     * List users who can be impersonated.
     */
    public function index(Request $request)
    {
        /** @var User $user */
        $user = $request->user();
        
        $isAdmin = $user->roles()->whereIn('roles.name', ['super_admin', 'Super Admin', 'super-admin'])->exists();

        if (!$isAdmin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Get users who do NOT have any administrative roles
        // We use a direct DB check to avoid guard-related filtering issues
        $users = User::whereDoesntHave('roles', function ($query) {
            $query->whereIn('roles.name', ['super_admin', 'Super Admin', 'super-admin']);
        })
        ->with(['roles', 'employee', 'employee.office'])
        ->get();

        return response()->json($users);
    }

    /**
     * Impersonate a user and return a Sanctum token.
     * Only available for Super Admins.
     */
    public function impersonate(Request $request, User $user)
    {
        /** @var User $currentUser */
        $currentUser = $request->user();

        $isAdmin = $currentUser->roles()->whereIn('roles.name', ['super_admin', 'Super Admin', 'super-admin'])->exists();

        if (!$isAdmin) {
            return response()->json([
                'message' => 'Unauthorized. Only Super Admins can impersonate.'
            ], 403);
        }

        $isDestAdmin = $user->roles->any(function ($role) {
            $name = strtolower($role->name);
            return $name === 'super admin' || $name === 'super_admin';
        });

        if ($isDestAdmin) {
            return response()->json([
                'message' => 'Cannot impersonate another Super Admin.'
            ], 403);
        }

        // Generate token for the target user
        $token = $user->createToken('mobile-impersonation')->plainTextToken;

        return response()->json([
            'message' => "Successfully impersonating {$user->name}",
            'user' => $user->load('roles'),
            'token' => $token,
        ]);
    }
}
