<?php

namespace App\Http\Middleware;

use App\Models\ApiLog;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class LogApiRequests
{
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);

        $response = $next($request);

        $executionTime = (microtime(true) - $startTime) * 1000;

        ApiLog::create([
            'endpoint' => $request->path(),
            'method' => $request->method(),
            'request_body' => json_encode($request->all()),
            'response_body' => $response->getContent(),
            'status_code' => $response->getStatusCode(),
            'execution_time_ms' => round($executionTime, 2)
        ]);

        return $response;
    }
}
