<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Http\Request;

class DashboardController
{
    public function index()
    {
        $totalTransactions = Transaction::count();
        $totalAmount = Transaction::sum('amount');
        $successTransactions = Transaction::where('status', 'SUCCESS')->count();
        $pendingTransactions = Transaction::where('status', 'PENDING')->count();
        $refundedTransactions = Transaction::where('status', 'REFUNDED')->count();

        $recentTransactions = Transaction::with('createdBy')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'total_transactions' => $totalTransactions,
            'total_amount' => $totalAmount,
            'success_transactions' => $successTransactions,
            'pending_transactions' => $pendingTransactions,
            'refunded_transactions' => $refundedTransactions,
            'recent_transactions' => $recentTransactions
        ]);
    }
}
