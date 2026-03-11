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
        if (!$request->user()->hasRole('Super Admin')) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $users = User::whereDoesntHave('roles', function ($query) {
            $query->where('name', 'Super Admin');
        })->get();

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

        if (!$currentUser->hasRole('Super Admin')) {
            return response()->json([
                'message' => 'Unauthorized. Only Super Admins can impersonate.'
            ], 403);
        }

        if ($user->hasRole('Super Admin')) {
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
