<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Support\Money;

class Invoice extends Model
{
    protected $fillable = ['amount_cents', 'currency'];

    public function formattedAmount(): string
    {
        return Money::format($this->amount_cents, $this->currency);
    }
}
