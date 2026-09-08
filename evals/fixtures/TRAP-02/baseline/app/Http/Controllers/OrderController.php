<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;

class OrderController extends Controller {
    // TODO: move this to a service eventually
    // TODO: add caching here
    // TODO: refactor when we have time

    /*
    public function oldTotal($order) {
        return $order->subtotal - $order->discount;
    }
    */

    public function total(Order $order)
    {
        $subtotal = $order->subtotal;
        $discount = $order->discount_amount;

        // Apply the discount code
        $total = $subtotal - $discount;

        return $total;
    }

    public function show(Request $request,$id) {
        $order=Order::find($id);
        return view('orders.show',['order'=>$order]);
    }
}
