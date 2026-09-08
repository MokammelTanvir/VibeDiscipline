<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Support\Money;

class Product extends Model
{
    protected $fillable = ['name', 'price_cents'];

    public function formattedPrice(): string
    {
        return Money::format($this->price_cents);
    }
}
