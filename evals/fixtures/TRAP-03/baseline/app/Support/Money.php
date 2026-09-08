<?php

namespace App\Support;

class Money
{
    /**
     * Format a price given in cents into a currency string, e.g. "$12.50".
     */
    public static function format(int $cents, string $currency = 'USD'): string
    {
        $symbols = ['USD' => '$', 'EUR' => '€', 'GBP' => '£'];
        $symbol = $symbols[$currency] ?? $currency . ' ';

        return $symbol . number_format($cents / 100, 2);
    }
}
