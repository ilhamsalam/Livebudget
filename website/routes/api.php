<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\TaxCalculationController;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// ==================== PUBLIC ROUTES (tanpa autentikasi) ====================
Route::post('/register', function (Request $request) {
    $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|string|email|max:255|unique:users',
        'password' => 'required|string|min:6|confirmed',
    ]);

    $user = User::create([
        'name' => $request->name,
        'email' => $request->email,
        'password' => Hash::make($request->password),
    ]);

    $token = $user->createToken('mobile')->plainTextToken;

    return response()->json([
        'user' => $user,
        'token' => $token,
    ], 201);
});

Route::post('/login', function (Request $request) {
    $request->validate([
        'email' => 'required|email',
        'password' => 'required',
    ]);

    $user = User::where('email', $request->email)->first();

    if (!$user || !Hash::check($request->password, $user->password)) {
        throw ValidationException::withMessages([
            'email' => ['The provided credentials are incorrect.'],
        ]);
    }

    $token = $user->createToken('mobile')->plainTextToken;

    return response()->json([
        'user' => $user,
        'token' => $token,
    ]);
});

// ==================== PROTECTED ROUTES (memerlukan token Sanctum) ====================
Route::middleware('auth:sanctum')->group(function () {
    // Get authenticated user
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Kalkulasi PPh 21
    Route::post('/calculate', [TaxCalculationController::class, 'calculate']);
    Route::get('/history/{user_id}', [TaxCalculationController::class, 'history']);
    Route::get('/public-history', [TaxCalculationController::class, 'publicHistory']);
    Route::put('/update/{id}', [TaxCalculationController::class, 'update']);
    Route::delete('/delete/{id}', [TaxCalculationController::class, 'destroy']);
});